class_name SpeechVisual
extends NodeVisual

static func describe(node: Resource) -> String:
	return "%s: %s" % [node.speaker, node.text]

static func outgoing_ids(node: Resource) -> Array[String]:
	var ids: Array[String] = node.response_ids.duplicate()
	if node.fallback_id != "":
		ids.append(node.fallback_id)
	return ids

static func color() -> Color:
	return Color(0.2, 0.45, 0.75)

static func can_connect_to(node: Resource, target: Resource) -> bool:
	return not (target is EntryNode)

static func connection_patch(node: Resource, target: Resource) -> Dictionary:
	if target is ResponseNode:
		if node.response_ids.has(target.id):
			return {}
		var new_ids: Array[String] = node.response_ids.duplicate()
		new_ids.append(target.id)
		return {"property": "response_ids", "value": new_ids}
	return {"property": "fallback_id", "value": target.id}

static func disconnection_patch(node: Resource, target_id: String) -> Dictionary:
	if node.response_ids.has(target_id):
		var new_ids: Array[String] = node.response_ids.duplicate()
		new_ids.erase(target_id)
		return {"property": "response_ids", "value": new_ids}
	if node.fallback_id == target_id:
		return {"property": "fallback_id", "value": ""}
	return {}

static func remap_ids(node: Resource, id_map: Dictionary) -> void:
	var new_response_ids: Array[String] = []
	for rid in node.response_ids:
		if id_map.has(rid):
			new_response_ids.append(id_map[rid])
	node.response_ids = new_response_ids
	node.fallback_id = id_map.get(node.fallback_id, "")
