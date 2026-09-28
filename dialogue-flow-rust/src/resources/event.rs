use godot::classes::Resource;
use godot::prelude::*;

/// Fires a named event to external systems and continues automatically.
/// Doesn't know or care what the event means — that's up to whatever
/// listens to `DialogueController.event_emitted`.
#[derive(GodotClass)]
#[class(tool, init, base=Resource)]
pub struct EventNode {
    base: Base<Resource>,

    #[export]
    pub id: GString,
    #[export]
    pub editor_position: Vector2,

    #[export]
    pub event_name: StringName,
    #[export]
    pub payload: Dictionary<GString, Variant>,

    /// Target node ID. Must not point at another `EntryNode` or a `ResponseNode`.
    #[export]
    pub next_id: GString,
}
