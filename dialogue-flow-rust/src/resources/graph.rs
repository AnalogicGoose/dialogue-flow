use godot::classes::Resource;
use godot::prelude::*;

/// Root resource: a complete conversation graph, saved/loaded as a `.tres`.
///
/// Nodes are stored as `Array<Gd<Resource>>` since gdext doesn't support
/// inheriting one custom class from another. Downcast with `Gd::try_cast`
/// when a specific node kind is needed.
#[derive(GodotClass)]
#[class(tool, init, base=Resource)]
pub struct ConversationGraph {
    base: Base<Resource>,

    #[export]
    pub nodes: Array<Gd<Resource>>,
}

#[godot_api]
impl ConversationGraph {
    /// Validates this graph without running it. Returns a Dictionary with
    /// `errors: Array[String]` (blocking problems) and
    /// `warnings: Array[String]` (non-blocking, worth knowing about).
    /// See Phase 11 in the roadmap and graph-specification.md.
    #[func]
    pub fn validate(&self) -> Dictionary<GString, Variant> {
        let (errors, warnings) = crate::graph::validate(&self.nodes);
        let mut result: Dictionary<GString, Variant> = Dictionary::new();
        let errors: Array<GString> = errors.into_iter().collect();
        let warnings: Array<GString> = warnings.into_iter().collect();
        result.set("errors", &errors);
        result.set("warnings", &warnings);
        result
    }
}