class_name DialogueGraphEdit
extends GraphEdit

var editor: Control

func _is_node_hover_valid(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> bool:
	if editor == null:
		return true
	return editor.is_connection_valid(from_node, to_node)
