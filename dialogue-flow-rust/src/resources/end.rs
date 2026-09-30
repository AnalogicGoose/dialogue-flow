use godot::classes::Resource;
use godot::prelude::*;

/// Terminal node. No outgoing edge; reaching it ends the conversation.
#[derive(GodotClass)]
#[class(tool, init, base=Resource)]
pub struct EndNode {
    base: Base<Resource>,

    #[var(usage_flags = [DEFAULT, READ_ONLY])]
    pub id: GString,
    
    #[var(usage_flags = [NO_EDITOR])]
    pub editor_position: Vector2,
}