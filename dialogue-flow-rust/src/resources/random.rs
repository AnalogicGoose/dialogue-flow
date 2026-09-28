use godot::classes::Resource;
use godot::prelude::*;

/// One weighted option inside a RandomNode
#[derive(GodotClass)]
#[class(init, base=Resource)]
pub struct RandomBranch {
    base: Base<Resource>,

    #[export]
    pub target_id: GString,
    #[export]
    pub weight: f64,
}

/// Picks one of several weighted branches at random and continues
/// automatically. A branch with weight 0 (or all branches at 0) is
/// effectively/entirely excluded.
#[derive(GodotClass)]
#[class(init, base=Resource)]
pub struct RandomNode {
    base: Base<Resource>,

    #[export]
    pub id: GString,
    #[export]
    pub editor_position: Vector2,

    #[export]
    pub branches: Array<Gd<RandomBranch>>,
}