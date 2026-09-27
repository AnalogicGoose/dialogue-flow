use godot::classes::Resource;
use godot::prelude::*;

/// Root resource: a complete conversation graph, saved/loaded as a `.tres`.
///
/// Nodes are stored as `Array<Gd<Resource>>` since gdext doesn't support
/// inheriting one custom class from another. Downcast with `Gd::try_cast`
/// when a specific node kind is needed.
#[derive(GodotClass)]
#[class(init, base=Resource)]
pub struct ConversationGraph {
    base: Base<Resource>,

    #[export]
    pub nodes: Array<Gd<Resource>>,
}