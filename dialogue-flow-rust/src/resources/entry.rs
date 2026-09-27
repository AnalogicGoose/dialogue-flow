use godot::classes::Resource;
use godot::prelude::*;

/// Graph start marker. A `ConversationGraph` has exactly one; traversal
/// always begins here.
#[derive(GodotClass)]
#[class(init, base=Resource)]
pub struct EntryNode {
    base: Base<Resource>,

    /// Stable, author-assigned, graph-unique identifier.
    #[export]
    pub id: GString,

    /// Position in the future visual graph editor. Not runtime semantics.
    #[export]
    pub editor_position: Vector2,

    /// Target node ID. Must not point at another `EntryNode` or a `ResponseNode`.
    #[export]
    pub next_id: GString,
}