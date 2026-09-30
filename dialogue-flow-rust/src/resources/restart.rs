use godot::classes::Resource;
use godot::prelude::*;

/// Jumps back to the graph's `Entry`. No stored target — the destination
/// is always Entry, per the spec.
#[derive(GodotClass)]
#[class(tool, init, base=Resource)]
pub struct RestartNode {
    base: Base<Resource>,

    #[var(usage_flags = [DEFAULT, READ_ONLY])]
    pub id: GString,
    
    #[var(usage_flags = [NO_EDITOR])]
    pub editor_position: Vector2,
}