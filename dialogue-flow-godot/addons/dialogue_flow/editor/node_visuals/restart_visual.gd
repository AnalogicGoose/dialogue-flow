class_name RestartVisual
extends NodeVisual

static func configure_slots(gnode: GraphNode, node: Resource, row_count: int) -> void:
	gnode.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)

static func color() -> Color:
	return Color(0.15, 0.45, 0.2)

static func can_be_source() -> bool:
	return false
