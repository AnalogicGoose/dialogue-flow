class_name RandomVisual
extends NodeVisual

static func outgoing_ids(node: Resource) -> Array[String]:
	var ids: Array[String] = []
	for b in node.branches:
		ids.append(b.target_id)
	return ids

static func color() -> Color:
	return Color(0.8, 0.3, 0.55)

# Same reasoning as ConditionVisual: one generic output slot can't express
# which branch a drag-connect targets, so branches stay Inspector-edited.
static func can_connect_to(node: Resource, target: Resource) -> bool:
	return false
