use godot::classes::Resource;
use godot::prelude::*;

/// Jumps back to the graph's `Entry`. No stored target — the destination
/// is always Entry, per the spec.
#[derive(GodotClass)]
#[class(init, base=Resource)]
pub struct RestartNode {
    base: Base<Resource>,

    #[export]
    pub id: GString,
    #[export]
    pub editor_position: Vector2,
}