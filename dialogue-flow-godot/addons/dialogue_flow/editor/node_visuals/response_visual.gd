class_name ResponseVisual
extends NodeVisual

static func describe(node: Resource) -> String:
	return node.text

static func outgoing_ids(node: Resource) -> Array[String]:
	return [node.next_id]

static func color() -> Color:
	return Color(0.3, 0.65, 0.7)

static func remap_ids(node: Resource, id_map: Dictionary) -> void:
	node.next_id = id_map.get(node.next_id, "")
