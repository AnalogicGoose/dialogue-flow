use godot::classes::Resource;
use godot::prelude::*;

/// Pure passthrough. Exists mainly for editor readability once the
/// visual graph editor (Phase 12) can use it to declutter long wires.
#[derive(GodotClass)]
#[class(init, base=Resource)]
pub struct RerouteNode {
    base: Base<Resource>,

    #[export]
    pub id: GString,
    #[export]
    pub editor_position: Vector2,

    #[export]
    pub next_id: GString,
}