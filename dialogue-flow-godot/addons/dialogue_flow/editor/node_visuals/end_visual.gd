class_name EndVisual
extends NodeVisual

static func configure_slots(gnode: GraphNode, node: Resource) -> void:
	gnode.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)

static func color() -> Color:
	return Color(0.75, 0.25, 0.25)

static func can_be_source() -> bool:
	return false
