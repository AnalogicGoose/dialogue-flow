@tool
extends EditorPlugin

var graph_editor: Control
var current_graph: ConversationGraph

func _enter_tree():
	graph_editor = preload("res://addons/dialogue_flow/editor/graph_editor.gd").new()
	graph_editor.plugin = self
	graph_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph_editor.custom_minimum_size = Vector2(0, 400)
	EditorInterface.get_editor_main_screen().add_child(graph_editor)
	_make_visible(false)

func _exit_tree():
	if graph_editor:
		graph_editor.queue_free()

# Called by Godot on Ctrl+S (and tab-switch, editor-close) -- this is
# where pending in-memory changes (e.g. a dragged node's editor_position,
# committed via EditorUndoRedoManager) actually get written to disk.
func _apply_changes() -> void:
	if current_graph == null:
		return
	var err := ResourceSaver.save(current_graph, current_graph.resource_path)
	if err != OK:
		push_error("DialogueFlow: failed to save (%s)" % err)
	else:
		graph_editor.mark_saved()

func _has_main_screen() -> bool:
	return true

func _get_plugin_name() -> String:
	return "DialogueFlow"

func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")

func _handles(object: Object) -> bool:
	return object is ConversationGraph

func _edit(object: Object) -> void:
	current_graph = object as ConversationGraph
	if current_graph:
		graph_editor.load_graph(current_graph)

func _make_visible(visible: bool) -> void:
	if graph_editor:
		graph_editor.visible = visible
