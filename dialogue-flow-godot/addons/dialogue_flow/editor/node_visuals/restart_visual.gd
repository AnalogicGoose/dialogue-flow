class_name RestartVisual
extends NodeVisual

static func configure_slots(gnode: GraphNode, node: Resource) -> void:
	gnode.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
