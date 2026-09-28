use godot::classes::Resource;
use godot::prelude::*;

/// A single player-facing choice. Only ever reached as a child of the
/// `SpeechNode` that lists its ID in `response_ids` — never targeted by a
/// generic edge from another node.
#[derive(GodotClass)]
#[class(tool, init, base=Resource)]
pub struct ResponseNode {
    base: Base<Resource>,

    #[export]
    pub id: GString,
    #[export]
    pub editor_position: Vector2,

    #[export(multiline)]
    pub text: GString,

    /// If set, this response is only offered when this state variable is
    /// truthy — an unset or empty name means always visible.
    #[export]
    pub required_variable: StringName,

    /// Target node ID. Must not point at another `EntryNode` or a `ResponseNode`.
    #[export]
    pub next_id: GString,
}