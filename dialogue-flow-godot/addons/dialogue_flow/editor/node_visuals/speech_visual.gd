class_name SpeechVisual
extends NodeVisual

static func describe(node: Resource) -> String:
	return "%s: %s" % [node.speaker, node.text]

static func outgoing_ids(node: Resource) -> Array[String]:
	var ids: Array[String] = node.response_ids.duplicate()
	if node.fallback_id != "":
		ids.append(node.fallback_id)
	return ids
