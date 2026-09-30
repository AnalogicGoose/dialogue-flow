class_name DialogueGraphEdit
extends GraphEdit

var editor: Control

func _is_node_hover_valid(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> bool:
	if editor == null:
		return true
	return editor.is_connection_valid(from_node, from_port, to_node, to_port)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed:
		if event.keycode == KEY_D or event.keycode == KEY_W:
			if editor != null:
				editor.duplicate_selected_nodes()
			accept_event()
		elif event.keycode == KEY_C:
			if editor != null:
				editor.copy_selected_nodes()
			accept_event()
		elif event.keycode == KEY_V:
			if editor != null:
				editor.paste_nodes()
			accept_event()
