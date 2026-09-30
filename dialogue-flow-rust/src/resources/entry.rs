use godot::classes::Resource;
use godot::prelude::*;

/// Graph start marker. A `ConversationGraph` has exactly one; traversal
/// always begins here.
#[derive(GodotClass)]
#[class(tool, init, base=Resource)]
pub struct EntryNode {
    base: Base<Resource>,

    /// Stable, author-assigned, graph-unique identifier.
    #[var(usage_flags = [DEFAULT, READ_ONLY])]
    pub id: GString,

    #[var(usage_flags = [NO_EDITOR])]
    pub editor_position: Vector2,

    /// Target node ID. Must not point at another `EntryNode` or a `ResponseNode`.
    #[export]
    pub next_id: GString,
}