class_name ConditionVisual
extends NodeVisual

static func describe(node: Resource) -> String:
	return str(node.variable_name)

static func outgoing_ids(node: Resource) -> Array[String]:
	return [node.true_id, node.false_id]

# Labeled True/False pins (Blueprint Branch-node style, per the roadmap's
# Design Reference) need a 2-row GraphNode body -- single generic output
# slot for now, both edges still drawn correctly via outgoing_ids above.
