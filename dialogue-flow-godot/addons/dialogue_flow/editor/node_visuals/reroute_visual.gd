class_name RerouteVisual
extends NodeVisual

static func outgoing_ids(node: Resource) -> Array[String]:
	return [node.next_id]

static func remap_ids(node: Resource, id_map: Dictionary) -> void:
	node.next_id = id_map.get(node.next_id, "")
