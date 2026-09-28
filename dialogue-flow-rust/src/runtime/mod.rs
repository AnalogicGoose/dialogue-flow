//! Runtime execution: traverses a conversation graph and drives the
//! Godot-facing `DialogueController` node.
//!
//! Depends on [`graph`](crate::graph) and [`resources`](crate::resources)
//! but knows nothing about presentation; the dialogue UI only talks to this
//! module through signals and public methods (see Phase 3/4 of the roadmap).

use std::collections::HashMap;
use godot::classes::{Node, Resource};
use godot::prelude::*;

use crate::resources::{
    ConversationGraph, EndNode, EntryNode, EventNode, ResponseNode, SpeechNode, WaitForEventNode
};

const MAX_AUTOMATIC_STEPS: u32 = 1000;

/// Executes a [`ConversationGraph`], per the rules in
/// `docs/graph-specification.md`. Knows nothing about presentation; talks to
/// the dialogue UI only through signals and `start`/`stop`/`cancel`/`choose`.
#[derive(GodotClass)]
#[class(base=Node)]
pub struct DialogueController {
    base: Base<Node>,

    #[export]
    pub conversation: Option<Gd<ConversationGraph>>,

    current_id: GString,
    node_index: HashMap<GString, Gd<Resource>>,
    running: bool,
}

#[godot_api]
impl INode for DialogueController {
    fn init(base: Base<Self::Base>) -> Self {
        Self {
            base,
            conversation: None,
            current_id: GString::new(),
            node_index: HashMap::new(),
            running: false,
        }
    }
}

fn node_id(node: &Gd<Resource>) -> GString {
    node.get("id").to::<GString>()
}

#[godot_api]
impl DialogueController {
    #[signal]
    fn dialogue_started();
    #[signal]
    fn dialogue_finished();
    #[signal]
    fn dialogue_cancelled();
    #[signal]
    fn speech_changed(speaker: GString, text: GString);
    #[signal]
    fn responses_changed(response_texts: Array<GString>);
    #[signal]
    fn event_emitted(event_name: StringName, payload: Dictionary<GString, Variant>);

    /// Resets state, finds the graph's `EntryNode`, and traverses until the
    /// first pausing node or `End`.
    #[func]
    pub fn start(&mut self) {
        self.reset();

        let Some(conversation) = self.conversation.clone() else {
            godot_error!("DialogueController.start(): no conversation assigned");
            return;
        };

        self.node_index = conversation
            .bind()
            .nodes
            .iter_shared()
            .map(|node| (node_id(&node), node))
            .collect();

        let entry_id = self
            .node_index
            .values()
            .find(|node| node.get_class() == "EntryNode")
            .map(node_id);

        let Some(entry_id) = entry_id else {
            godot_error!("DialogueController.start(): conversation has no EntryNode");
            return;
        };

        self.running = true;
        self.base_mut().emit_signal("dialogue_started", &[]);
        self.enter(entry_id, 0);
    }

    /// Quiet reset, with no signal. Used for teardown/reuse.
    #[func]
    pub fn stop(&mut self) {
        self.reset();
    }

    /// Aborts an in-progress conversation and emits `dialogue_cancelled`.
    #[func]
    pub fn cancel(&mut self) {
        if !self.running {
            return;
        }
        self.reset();
        self.base_mut().emit_signal("dialogue_cancelled", &[]);
    }

    /// Picks the `index`-th response of the currently paused `SpeechNode`
    /// and resumes traversal from it.
    #[func]
    pub fn choose(&mut self, index: i64) {
        if !self.running {
            godot_error!("DialogueController.choose(): no dialogue running");
            return;
        }

        let Some(current) = self.node_index.get(&self.current_id).cloned() else {
            godot_error!("DialogueController.choose(): current node missing");
            return;
        };
        let Ok(speech) = current.try_cast::<SpeechNode>() else {
            godot_error!("DialogueController.choose(): current node is not a SpeechNode");
            return;
        };

        let response_ids = speech.bind().response_ids.clone();
        let Some(response_id) = response_ids.get(index as usize) else {
            godot_error!("DialogueController.choose(): index {} out of range", index);
            return;
        };

        self.enter(response_id, 0);
    }

    /// Delivers an external event. Ignored (not an error) if no dialogue
    /// is running, the current node isn't a `WaitForEventNode`, or the
    /// name doesn't match what it's waiting for.
    #[func]
    pub fn receive_event(&mut self, event_name: StringName, payload: Dictionary<GString, Variant>) {
        let _ = payload; // accepted for symmetry with event_emitted; not yet consumed (see Phase 9)

        if !self.running {
            return;
        }

        let Some(current) = self.node_index.get(&self.current_id).cloned() else {
            return;
        };
        let Ok(waiting) = current.try_cast::<WaitForEventNode>() else {
            return;
        };
        let (waiting_for, next_id) = {
            let bound = waiting.bind();
            (bound.event_name.clone(), bound.next_id.clone())
        };
        if waiting_for != event_name {
            return;
        }
        self.enter(next_id, 0);
    }

    fn reset(&mut self) {
        self.running = false;
        self.current_id = GString::new();
        self.node_index.clear();
    }

    /// Enters `id` and keeps auto-advancing through non-pausing nodes,
    /// guarded by `steps` against an infinite automatic loop.
    fn enter(&mut self, id: GString, steps: u32) {
        if steps > MAX_AUTOMATIC_STEPS {
            godot_error!(
                "DialogueController: automatic traversal exceeded {} steps, possible infinite loop",
                MAX_AUTOMATIC_STEPS
            );
            self.reset();
            return;
        }

        let Some(node) = self.node_index.get(&id).cloned() else {
            godot_error!("DialogueController: dangling node reference '{}'", id);
            self.reset();
            return;
        };
        self.current_id = id.clone();

        let class = node.get_class();

        if class == "EntryNode" {
            let next_id = node.try_cast::<EntryNode>().unwrap().bind().next_id.clone();
            self.enter(next_id, steps + 1);
        } else if class == "SpeechNode" {
            let speech = node.try_cast::<SpeechNode>().unwrap();
            let (speaker, text, response_ids, fallback_id) = {
                let bound = speech.bind();
                (
                    bound.speaker.clone(),
                    bound.text.clone(),
                    bound.response_ids.clone(),
                    bound.fallback_id.clone(),
                )
            };
            self.base_mut()
                .emit_signal("speech_changed", &[speaker.to_variant(), text.to_variant()]);

            if response_ids.is_empty() {
                self.enter(fallback_id, steps + 1);
            } else {
                let response_texts: Array<GString> = response_ids
                    .iter_shared()
                    .filter_map(|rid| self.node_index.get(&rid).cloned())
                    .filter_map(|n| n.try_cast::<ResponseNode>().ok())
                    .map(|r| r.bind().text.clone())
                    .collect();
                self.base_mut()
                    .emit_signal("responses_changed", &[response_texts.to_variant()]);
                // Pauses here until choose() is called.
            }
        } else if class == "EventNode" {
            let event = node.try_cast::<EventNode>().unwrap();
            let (event_name, payload, next_id) = {
                let bound = event.bind();
                (
                    bound.event_name.clone(),
                    bound.payload.clone(),
                    bound.next_id.clone(),
                )
            };
            self.base_mut().emit_signal(
                "event_emitted",
                &[event_name.to_variant(), payload.to_variant()],
            );
            self.enter(next_id, steps + 1);
        } else if class == "WaitForEventNode" {
            // Clears any stale response buttons left over from before the pause.
            self.base_mut()
                .emit_signal("responses_changed", &[Array::<GString>::new().to_variant()]);
            // Pauses here until receive_event() delivers a matching event.
        } else if class == "ResponseNode" {
            let next_id = node
                .try_cast::<ResponseNode>()
                .unwrap()
                .bind()
                .next_id
                .clone();
            self.enter(next_id, steps + 1);
        } else if class == "EndNode" {
            let _ = node.try_cast::<EndNode>().unwrap();
            self.running = false;
            self.base_mut().emit_signal("dialogue_finished", &[]);
        } else {
            godot_error!("DialogueController: unsupported node class '{}'", class);
            self.reset();
        }
    }
}