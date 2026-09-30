class_name EventVisual
extends NodeVisual

static func describe(node: Resource) -> String:
	return str(node.event_name)

static func outgoing_ids(node: Resource) -> Array[String]:
	return [node.next_id]

static func color() -> Color:
	return Color(0.8, 0.5, 0.2)

static func remap_ids(node: Resource, id_map: Dictionary) -> void:
	node.next_id = id_map.get(node.next_id, "")
