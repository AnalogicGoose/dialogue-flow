use godot::classes::Resource;
use godot::prelude::*;

/// Terminal node. No outgoing edge; reaching it ends the conversation.
#[derive(GodotClass)]
#[class(tool, init, base=Resource)]
pub struct EndNode {
    base: Base<Resource>,

    #[export]
    pub id: GString,
    #[export]
    pub editor_position: Vector2,
}