class_name EntryVisual
extends NodeVisual

static func outgoing_ids(node: Resource) -> Array[String]:
	return [node.next_id]

static func configure_slots(gnode: GraphNode, node: Resource) -> void:
	gnode.set_slot(0, false, 0, Color.WHITE, true, 0, Color.WHITE)

static func color() -> Color:
	return Color(0.25, 0.65, 0.3)
