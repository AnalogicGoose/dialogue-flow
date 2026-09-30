class_name SpeechVisual
extends NodeVisual

static func describe(node: Resource) -> String:
	return "%s: %s" % [node.speaker, node.text]

static func outgoing_ids(node: Resource) -> Array[String]:
	var ids: Array[String] = node.response_ids.duplicate()
	if node.fallback_id != "":
		ids.append(node.fallback_id)
	return ids

# One row per response_ids entry (may be blank/unwired), plus a fixed
# trailing Fallback row that's always present regardless of response
# count -- never removable, since it's a real field on every SpeechNode,
# not an optional dynamic pin.
static func output_rows(node: Resource) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for i in node.response_ids.size():
		var rid: String = node.response_ids[i]
		rows.append({"label": "Response %d" % (i + 1), "target_id": rid, "removable": rid == ""})
	rows.append({"label": "Fallback", "target_id": node.fallback_id, "removable": false})
	return rows

static func supports_dynamic_pins() -> bool:
	return true

static func add_pin_patch(node: Resource) -> Dictionary:
	var new_ids: Array[String] = node.response_ids.duplicate()
	new_ids.append("")
	return {"property": "response_ids", "value": new_ids}

# row_index is always a response row here -- the Fallback row (always
# last in output_rows()) is never marked removable, so graph_editor.gd
# never calls this for it.
static func remove_pin_patch(node: Resource, row_index: int) -> Dictionary:
	var new_ids: Array[String] = node.response_ids.duplicate()
	new_ids.remove_at(row_index)
	return {"property": "response_ids", "value": new_ids}

static func color() -> Color:
	return Color(0.2, 0.45, 0.75)

# port indexes output_rows() above: 0..response_ids.size()-1 are response
# rows (must target a ResponseNode), response_ids.size() is the trailing
# Fallback row (must target anything else) -- the same "connect to a
# Response -> response_ids, connect to anything else -> fallback_id"
# rule as before, just keyed by which pin was dragged instead of by the
# target's type, now that each has its own pin.
static func can_connect_to(node: Resource, target: Resource, port: int = 0) -> bool:
	if target is EntryNode:
		return false
	if port >= node.response_ids.size():
		return not (target is ResponseNode)
	return target is ResponseNode

static func connection_patch(node: Resource, target: Resource, port: int = 0) -> Dictionary:
	if port >= node.response_ids.size():
		return {"property": "fallback_id", "value": target.id}
	var new_ids: Array[String] = node.response_ids.duplicate()
	new_ids[port] = target.id
	return {"property": "response_ids", "value": new_ids}

static func disconnection_patch(node: Resource, target_id: String, port: int = 0) -> Dictionary:
	if port >= node.response_ids.size():
		if node.fallback_id == target_id:
			return {"property": "fallback_id", "value": ""}
		return {}
	if node.response_ids[port] == target_id:
		var new_ids: Array[String] = node.response_ids.duplicate()
		new_ids[port] = ""
		return {"property": "response_ids", "value": new_ids}
	return {}

# Preserves row count/order across duplicate and paste: every response
# slot (wired or already blank) stays a slot, just re-pointed at the new
# id if its old target was part of the same duplicated/copied batch, or
# blanked (not dropped) if it pointed outside it.
static func remap_ids(node: Resource, id_map: Dictionary) -> void:
	var new_response_ids: Array[String] = []
	for rid in node.response_ids:
		new_response_ids.append(id_map.get(rid, ""))
	node.response_ids = new_response_ids
	node.fallback_id = id_map.get(node.fallback_id, "")
