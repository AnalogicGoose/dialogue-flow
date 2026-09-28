class_name RandomVisual
extends NodeVisual

static func outgoing_ids(node: Resource) -> Array[String]:
	var ids: Array[String] = []
	for b in node.branches:
		ids.append(b.target_id)
	return ids
