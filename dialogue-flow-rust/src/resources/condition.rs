use godot::classes::Resource;
use godot::prelude::*;

/// Branches on a named state value's truthiness (Godot's own truthy/falsy
/// rules — false/0/0.0/""/empty containers/nil are false, everything else
/// true). An unset variable is nil, so it takes the false branch.
#[derive(GodotClass)]
#[class(tool, init, base=Resource)]
pub struct ConditionNode {
    base: Base<Resource>,

    #[export]
    pub id: GString,
    #[export]
    pub editor_position: Vector2,

    #[export]
    pub variable_name: StringName,

    /// Both must not point at another `EntryNode` or a `ResponseNode`.
    #[export]
    pub true_id: GString,
    #[export]
    pub false_id: GString,
}