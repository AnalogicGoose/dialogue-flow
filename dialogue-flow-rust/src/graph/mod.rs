//! Static graph validation: checks a [`ConversationGraph`](crate::resources::ConversationGraph)
//! without running it. See `docs/DialogueFlow_Roadmap.md` Phase 11 and
//! `docs/graph-specification.md`'s validation-vs-runtime-error split.

use std::collections::{HashMap, HashSet};

use godot::classes::Resource;
use godot::prelude::*;

use crate::resources::{
    ConditionNode, EntryNode, EventNode, RandomNode, RerouteNode, ResponseNode, SpeechNode,
    WaitForEventNode,
};

fn node_id(node: &Gd<Resource>) -> GString {
    node.get("id").to::<GString>()
}

fn gs(s: String) -> GString {
    GString::from(&s)
}

/// Both must be non-empty and, if so, resolve to a node that isn't an
/// `EntryNode` or `ResponseNode` (per the connection-legality rule).
fn check_edge(
    index: &HashMap<GString, Gd<Resource>>,
    errors: &mut Vec<GString>,
    context: &str,
    target: &GString,
) {
    if target.is_empty() {
        errors.push(gs(format!("{context}: target is unset.")));
        return;
    }
    let Some(t) = index.get(target) else {
        errors.push(gs(format!("{context}: target '{target}' does not exist.")));
        return;
    };
    let class = t.get_class();
    if class == "EntryNode" {
        errors.push(gs(format!("{context}: target '{target}' is an EntryNode, which no edge may target.")));
    } else if class == "ResponseNode" {
        errors.push(gs(format!("{context}: target '{target}' is a ResponseNode, which no generic edge may target (only a Speech's response_ids may).")));
    }
}

/// Runs every Phase 11 check and returns `(errors, warnings)` as
/// human-readable messages, each naming the offending node's id.
pub fn validate(nodes: &Array<Gd<Resource>>) -> (Vec<GString>, Vec<GString>) {
    let mut errors: Vec<GString> = Vec::new();
    let mut warnings: Vec<GString> = Vec::new();

    // Pass 1: build the id index, catching empty and duplicate ids.
    let mut index: HashMap<GString, Gd<Resource>> = HashMap::new();
    for node in nodes.iter_shared() {
        let id = node_id(&node);
        let class = node.get_class();
        if id.is_empty() {
            errors.push(gs(format!("A {class} has an empty id.")));
            continue;
        }
        if index.contains_key(&id) {
            errors.push(gs(format!("Duplicate node id '{id}' (used by more than one node).")));
            continue;
        }
        index.insert(id, node);
    }

    // Pass 2: Entry count.
    let entry_ids: Vec<GString> = index
        .iter()
        .filter(|(_, n)| n.get_class() == "EntryNode")
        .map(|(id, _)| id.clone())
        .collect();
    if entry_ids.is_empty() {
        errors.push("Graph has no EntryNode.".into());
    } else if entry_ids.len() > 1 {
        let names: Vec<String> = entry_ids.iter().map(|s| s.to_string()).collect();
        errors.push(gs(format!("Graph has multiple EntryNodes: {}.", names.join(", "))));
    }
    // Reachability/cycle analysis only makes sense with exactly one Entry —
    // with zero or several, "unreachable from Entry" would be arbitrary
    // noise on top of the already-fatal error above.
    let entry_id = if entry_ids.len() == 1 {
        entry_ids.first().cloned()
    } else {
        None
    };

    // Pass 3: per-node-type field checks.
    for (id, node) in index.iter() {
        let class = node.get_class();
        if class == "EntryNode" {
            let next_id = node.clone().try_cast::<EntryNode>().unwrap().bind().next_id.clone();
            check_edge(&index, &mut errors, &format!("EntryNode '{id}'"), &next_id);
        } else if class == "SpeechNode" {
            let speech = node.clone().try_cast::<SpeechNode>().unwrap();
            let (response_ids, fallback_id) = {
                let bound = speech.bind();
                (bound.response_ids.clone(), bound.fallback_id.clone())
            };
            if response_ids.is_empty() && fallback_id.is_empty() {
                errors.push(gs(format!("SpeechNode '{id}' has neither responses nor a fallback_id — a dead end.")));
            }
            for rid in response_ids.iter_shared() {
                if rid.is_empty() {
                    errors.push(gs(format!("SpeechNode '{id}': a response_ids entry is empty.")));
                    continue;
                }
                match index.get(&rid) {
                    None => errors.push(gs(format!("SpeechNode '{id}': response_ids target '{rid}' does not exist."))),
                    Some(t) if t.get_class() != "ResponseNode" => {
                        errors.push(gs(format!("SpeechNode '{id}': response_ids target '{rid}' is a {}, not a ResponseNode.", t.get_class())));
                    }
                    _ => {}
                }
            }
            if !fallback_id.is_empty() {
                check_edge(&index, &mut errors, &format!("SpeechNode '{id}' fallback_id"), &fallback_id);
            }
        } else if class == "ResponseNode" {
            let next_id = node.clone().try_cast::<ResponseNode>().unwrap().bind().next_id.clone();
            check_edge(&index, &mut errors, &format!("ResponseNode '{id}'"), &next_id);
        } else if class == "EventNode" {
            let event = node.clone().try_cast::<EventNode>().unwrap();
            let (event_name, next_id) = {
                let bound = event.bind();
                (bound.event_name.clone(), bound.next_id.clone())
            };
            if event_name.is_empty() {
                warnings.push(gs(format!("EventNode '{id}' has an empty event_name.")));
            }
            check_edge(&index, &mut errors, &format!("EventNode '{id}'"), &next_id);
        } else if class == "ConditionNode" {
            let condition = node.clone().try_cast::<ConditionNode>().unwrap();
            let (variable_name, true_id, false_id) = {
                let bound = condition.bind();
                (bound.variable_name.clone(), bound.true_id.clone(), bound.false_id.clone())
            };
            if variable_name.is_empty() {
                warnings.push(gs(format!("ConditionNode '{id}' has an empty variable_name (always evaluates falsy).")));
            }
            check_edge(&index, &mut errors, &format!("ConditionNode '{id}' true_id"), &true_id);
            check_edge(&index, &mut errors, &format!("ConditionNode '{id}' false_id"), &false_id);
        } else if class == "RandomNode" {
            let random = node.clone().try_cast::<RandomNode>().unwrap();
            let branches = random.bind().branches.clone();
            if branches.is_empty() {
                errors.push(gs(format!("RandomNode '{id}' has no branches.")));
            }
            let mut total_weight = 0.0;
            for branch in branches.iter_shared() {
                let (target_id, weight) = {
                    let bound = branch.bind();
                    (bound.target_id.clone(), bound.weight)
                };
                if weight < 0.0 {
                    warnings.push(gs(format!("RandomNode '{id}': a branch has a negative weight ({weight}), treated as 0.")));
                }
                total_weight += weight.max(0.0);
                check_edge(&index, &mut errors, &format!("RandomNode '{id}' branch"), &target_id);
            }
            if !branches.is_empty() && total_weight <= 0.0 {
                errors.push(gs(format!("RandomNode '{id}': all branches have zero (or negative) weight — would always fail at runtime.")));
            }
        } else if class == "RerouteNode" {
            let next_id = node.clone().try_cast::<RerouteNode>().unwrap().bind().next_id.clone();
            check_edge(&index, &mut errors, &format!("RerouteNode '{id}'"), &next_id);
        } else if class == "WaitForEventNode" {
            let waiting = node.clone().try_cast::<WaitForEventNode>().unwrap();
            let (event_name, next_id) = {
                let bound = waiting.bind();
                (bound.event_name.clone(), bound.next_id.clone())
            };
            if event_name.is_empty() {
                warnings.push(gs(format!("WaitForEventNode '{id}' has an empty event_name.")));
            }
            check_edge(&index, &mut errors, &format!("WaitForEventNode '{id}'"), &next_id);
        }
        // RestartNode and EndNode have no outgoing fields to check.
    }

    // Pass 4: reachability from Entry, following every possible edge
    // (not just the one that would actually be taken at runtime).
    if let Some(entry_id) = &entry_id {
        let reachable = reachable_ids(&index, entry_id);
        for id in index.keys() {
            if !reachable.contains(id) {
                warnings.push(gs(format!("Node '{id}' is unreachable from Entry.")));
            }
        }

        // Pass 5: warn about cycles with no pausing node.
        if let Some(cycle) = find_non_pausing_cycle(&index, entry_id) {
            let names: Vec<String> = cycle.iter().map(|s| s.to_string()).collect();
            warnings.push(gs(format!(
                "Possible infinite loop: {} form a cycle with no pausing node (a Speech with responses, or a WaitForEvent).",
                names.join(" -> ")
            )));
        }
    }

    (errors, warnings)
}

/// All ids a node could ever send traversal to, ignoring which branch
/// would actually be taken at runtime — used for reachability.
fn all_possible_targets(node: &Gd<Resource>, entry_id: &GString) -> Vec<GString> {
    let class = node.get_class();
    if class == "EntryNode" {
        vec![node.clone().try_cast::<EntryNode>().unwrap().bind().next_id.clone()]
    } else if class == "SpeechNode" {
        let speech = node.clone().try_cast::<SpeechNode>().unwrap();
        let bound = speech.bind();
        let mut targets: Vec<GString> = bound.response_ids.iter_shared().collect();
        if !bound.fallback_id.is_empty() {
            targets.push(bound.fallback_id.clone());
        }
        targets
    } else if class == "ResponseNode" {
        vec![node.clone().try_cast::<ResponseNode>().unwrap().bind().next_id.clone()]
    } else if class == "EventNode" {
        vec![node.clone().try_cast::<EventNode>().unwrap().bind().next_id.clone()]
    } else if class == "ConditionNode" {
        let condition = node.clone().try_cast::<ConditionNode>().unwrap();
        let bound = condition.bind();
        vec![bound.true_id.clone(), bound.false_id.clone()]
    } else if class == "RandomNode" {
        let random = node.clone().try_cast::<RandomNode>().unwrap();
        random
            .bind()
            .branches
            .iter_shared()
            .map(|b| b.bind().target_id.clone())
            .collect()
    } else if class == "RestartNode" {
        vec![entry_id.clone()]
    } else if class == "RerouteNode" {
        vec![node.clone().try_cast::<RerouteNode>().unwrap().bind().next_id.clone()]
    } else if class == "WaitForEventNode" {
        vec![node.clone().try_cast::<WaitForEventNode>().unwrap().bind().next_id.clone()]
    } else {
        Vec::new() // EndNode
    }
}

fn reachable_ids(index: &HashMap<GString, Gd<Resource>>, entry_id: &GString) -> HashSet<GString> {
    let mut seen = HashSet::new();
    let mut stack = vec![entry_id.clone()];
    while let Some(id) = stack.pop() {
        if id.is_empty() || !seen.insert(id.clone()) {
            continue;
        }
        let Some(node) = index.get(&id) else { continue };
        for target in all_possible_targets(node, entry_id) {
            if !target.is_empty() && !seen.contains(&target) {
                stack.push(target);
            }
        }
    }
    seen
}

/// True if a node never pauses traversal (per graph-specification.md):
/// only a Speech with >=1 response, or WaitForEvent, pause.
fn is_pausing(node: &Gd<Resource>) -> bool {
    let class = node.get_class();
    if class == "WaitForEventNode" {
        return true;
    }
    if class == "SpeechNode" {
        let speech = node.clone().try_cast::<SpeechNode>().unwrap();
        return !speech.bind().response_ids.is_empty();
    }
    false
}

/// DFS cycle detection restricted to non-pausing nodes: if a cycle exists
/// using only nodes that never pause, that's a genuine automatic-loop
/// risk. Returns the first such cycle found, as an id path.
fn find_non_pausing_cycle(
    index: &HashMap<GString, Gd<Resource>>,
    entry_id: &GString,
) -> Option<Vec<GString>> {
    #[derive(PartialEq, Clone, Copy)]
    enum Color {
        White,
        Gray,
        Black,
    }

    let mut color: HashMap<GString, Color> = index.keys().map(|k| (k.clone(), Color::White)).collect();
    let mut path: Vec<GString> = Vec::new();

    fn visit(
        id: &GString,
        index: &HashMap<GString, Gd<Resource>>,
        entry_id: &GString,
        color: &mut HashMap<GString, Color>,
        path: &mut Vec<GString>,
    ) -> Option<Vec<GString>> {
        let Some(node) = index.get(id) else { return None };
        if is_pausing(node) {
            return None; // pausing nodes never contribute to an automatic cycle
        }
        color.insert(id.clone(), Color::Gray);
        path.push(id.clone());

        for target in all_possible_targets(node, entry_id) {
            if target.is_empty() {
                continue;
            }
            match color.get(&target).copied() {
                Some(Color::Gray) => {
                    // Found a back-edge into the current path: extract the cycle.
                    let start = path.iter().position(|p| *p == target).unwrap_or(0);
                    let mut cycle = path[start..].to_vec();
                    cycle.push(target);
                    return Some(cycle);
                }
                Some(Color::White) | None => {
                    if let Some(cycle) = visit(&target, index, entry_id, color, path) {
                        return Some(cycle);
                    }
                }
                Some(Color::Black) => {}
            }
        }

        path.pop();
        color.insert(id.clone(), Color::Black);
        None
    }

    for id in index.keys().cloned().collect::<Vec<_>>() {
        if color.get(&id).copied() == Some(Color::White) {
            if let Some(cycle) = visit(&id, index, entry_id, &mut color, &mut path) {
                return Some(cycle);
            }
        }
    }
    None
}