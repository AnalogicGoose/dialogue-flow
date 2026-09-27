use godot::classes::Resource;
use godot::prelude::*;

/// A single player-facing choice. Only ever reached as a child of the
/// `SpeechNode` that lists its ID in `response_ids` — never targeted by a
/// generic edge from another node.
#[derive(GodotClass)]
#[class(init, base=Resource)]
pub struct ResponseNode {
    base: Base<Resource>,

    #[export]
    pub id: GString,
    #[export]
    pub editor_position: Vector2,

    #[export(multiline)]
    pub text: GString,

    /// Target node ID. Must not point at another `EntryNode` or a `ResponseNode`.
    #[export]
    pub next_id: GString,
}