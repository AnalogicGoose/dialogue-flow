class_name ConditionVisual
extends NodeVisual

static func describe(node: Resource) -> String:
	return str(node.variable_name)

static func outgoing_ids(node: Resource) -> Array[String]:
	return [node.true_id, node.false_id]

# Labeled True/False pins (Blueprint Branch-node style, per the roadmap's
# Design Reference) -- each gets its own dedicated row/pin now, via the
# generic multi-row machinery in graph_editor.gd's _rebuild().
static func output_rows(node: Resource) -> Array[Dictionary]:
	return [
		{"label": "True", "target_id": node.true_id, "removable": false},
		{"label": "False", "target_id": node.false_id, "removable": false},
	]

static func color() -> Color:
	return Color(0.55, 0.35, 0.75)

# Drag-connect still isn't supported for a specific branch -- which pin a
# drag targets doesn't disambiguate which of the two fixed fields
# (true_id/false_id) it should become clearly enough to be worth wiring
# up yet, so true_id/false_id stay Inspector-edited. Both edges still
# render correctly on their own labeled row regardless of how they were
# set.
static func can_connect_to(node: Resource, target: Resource, port: int = 0) -> bool:
	return false

static func remap_ids(node: Resource, id_map: Dictionary) -> void:
	node.true_id = id_map.get(node.true_id, "")
	node.false_id = id_map.get(node.false_id, "")
