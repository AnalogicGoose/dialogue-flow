class_name EntryVisual
extends NodeVisual

static func outgoing_ids(node: Resource) -> Array[String]:
	return [node.next_id]

static func configure_slots(gnode: GraphNode, node: Resource, row_count: int) -> void:
	gnode.set_slot(0, false, 0, Color.WHITE, row_count <= 1, 0, Color.WHITE)

static func color() -> Color:
	return Color(0.25, 0.65, 0.3)

static func remap_ids(node: Resource, id_map: Dictionary) -> void:
	node.next_id = id_map.get(node.next_id, "")
