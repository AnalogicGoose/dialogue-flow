class_name RerouteVisual
extends NodeVisual

static func outgoing_ids(node: Resource) -> Array[String]:
	return [node.next_id]
