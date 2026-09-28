class_name ConditionVisual
extends NodeVisual

static func describe(node: Resource) -> String:
	return str(node.variable_name)

static func outgoing_ids(node: Resource) -> Array[String]:
	return [node.true_id, node.false_id]

static func color() -> Color:
	return Color(0.55, 0.35, 0.75)

# Single generic output slot can't tell which logical branch a drag-connect
# means, so drag-connect is rejected here -- true_id/false_id are still
# edited via the Inspector, and both resulting edges render correctly
# (outgoing_ids above draws them regardless of how they were set).
static func can_connect_to(node: Resource, target: Resource) -> bool:
	return false

# Labeled True/False pins (Blueprint Branch-node style, per the roadmap's
# Design Reference) need a 2-row GraphNode body -- single generic output
# slot for now, both edges still drawn correctly via outgoing_ids above.
