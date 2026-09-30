class_name RandomVisual
extends NodeVisual

static func outgoing_ids(node: Resource) -> Array[String]:
	var ids: Array[String] = []
	for b in node.branches:
		ids.append(b.target_id)
	return ids

# One row per branch, labeled with its weight -- each gets its own
# dedicated row/pin via the generic multi-row machinery in
# graph_editor.gd's _rebuild(). Adding/removing a branch itself stays
# Inspector-edited for now (see the roadmap's planned graph node visual
# refactor for extending dynamic add/remove here later).
static func output_rows(node: Resource) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for b in node.branches:
		rows.append({"label": "Weight %s" % b.weight, "target_id": b.target_id, "removable": false})
	return rows

static func color() -> Color:
	return Color(0.8, 0.3, 0.55)

# Same reasoning as ConditionVisual: which pin a drag targets doesn't
# disambiguate which branch entry it should become, so branches stay
# Inspector-edited.
static func can_connect_to(node: Resource, target: Resource, port: int = 0) -> bool:
	return false

static func remap_ids(node: Resource, id_map: Dictionary) -> void:
	for b in node.branches:
		b.target_id = id_map.get(b.target_id, "")
