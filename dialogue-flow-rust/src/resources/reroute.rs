use godot::classes::Resource;
use godot::prelude::*;

/// Pure passthrough. Exists mainly for editor readability once the
/// visual graph editor (Phase 12) can use it to declutter long wires.
#[derive(GodotClass)]
#[class(tool, init, base=Resource)]
pub struct RerouteNode {
    base: Base<Resource>,

    #[export]
    pub id: GString,
    
    #[var(usage_flags = [NO_EDITOR])]
    pub editor_position: Vector2,

    #[export]
    pub next_id: GString,
}