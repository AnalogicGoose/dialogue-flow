class_name EventVisual
extends NodeVisual

static func describe(node: Resource) -> String:
	return str(node.event_name)

static func outgoing_ids(node: Resource) -> Array[String]:
	return [node.next_id]
