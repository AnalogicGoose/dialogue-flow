class_name WaitForEventVisual
extends NodeVisual

static func describe(node: Resource) -> String:
	return str(node.event_name)

static func outgoing_ids(node: Resource) -> Array[String]:
	return [node.next_id]

static func color() -> Color:
	return Color(0.8, 0.75, 0.2)
