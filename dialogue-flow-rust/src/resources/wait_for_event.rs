use godot::classes::Resource;
use godot::prelude::*;

/// Pauses traversal until a matching event arrives via
/// `DialogueController::receive_event`.
#[derive(GodotClass)]
#[class(tool, init, base=Resource)]
pub struct WaitForEventNode {
    base: Base<Resource>,

    #[export]
    pub id: GString,
    #[export]
    pub editor_position: Vector2,

    /// The event name this node waits for. Other event names are ignored.
    #[export]
    pub event_name: StringName,

    /// Target node ID once the matching event arrives. Must not point at
    /// another `EntryNode` or a `ResponseNode`.
    #[export]
    pub next_id: GString,
}