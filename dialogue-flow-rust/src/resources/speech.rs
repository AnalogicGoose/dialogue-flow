use godot::classes::Resource;
use godot::prelude::*;

/// A line of dialogue, optionally followed by one or more player responses.
///
/// Exactly one of `response_ids` / `fallback_id` should be set: with
/// responses present, traversal pauses for `choose()`; with none, it
/// continues automatically via `fallback_id`.
#[derive(GodotClass)]
#[class(tool, init, base=Resource)]
pub struct SpeechNode {
    base: Base<Resource>,

    #[export]
    pub id: GString,
    
    #[var(usage_flags = [NO_EDITOR])]
    pub editor_position: Vector2,

    #[export]
    pub speaker: GString,

    #[export(multiline)]
    pub text: GString,

    /// IDs of this speech's `ResponseNode` children.
    #[export]
    pub response_ids: Array<GString>,

    /// Used only when `response_ids` is empty.
    #[export]
    pub fallback_id: GString,
}