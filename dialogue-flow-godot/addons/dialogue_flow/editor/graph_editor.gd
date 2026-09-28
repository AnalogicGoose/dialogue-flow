@tool
extends Control

const VISUALS := {
	"EntryNode": preload("res://addons/dialogue_flow/editor/node_visuals/entry_visual.gd"),
	"SpeechNode": preload("res://addons/dialogue_flow/editor/node_visuals/speech_visual.gd"),
	"ResponseNode": preload("res://addons/dialogue_flow/editor/node_visuals/response_visual.gd"),
	"EventNode": preload("res://addons/dialogue_flow/editor/node_visuals/event_visual.gd"),
	"ConditionNode": preload("res://addons/dialogue_flow/editor/node_visuals/condition_visual.gd"),
	"RandomNode": preload("res://addons/dialogue_flow/editor/node_visuals/random_visual.gd"),
	"WaitForEventNode": preload("res://addons/dialogue_flow/editor/node_visuals/wait_for_event_visual.gd"),
	"RerouteNode": preload("res://addons/dialogue_flow/editor/node_visuals/reroute_visual.gd"),
	"RestartNode": preload("res://addons/dialogue_flow/editor/node_visuals/restart_visual.gd"),
	"EndNode": preload("res://addons/dialogue_flow/editor/node_visuals/end_visual.gd"),
}
const DEFAULT_VISUAL := preload("res://addons/dialogue_flow/editor/node_visuals/node_visual.gd")

var plugin: EditorPlugin
var graph_edit: GraphEdit
var current_graph: ConversationGraph
var node_by_id: Dictionary = {}

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var toolbar := HBoxContainer.new()
	vbox.add_child(toolbar)
	var save_layout_button := Button.new()
	save_layout_button.text = "Save Layout"
	save_layout_button.pressed.connect(_on_save_layout_pressed)
	toolbar.add_child(save_layout_button)

	graph_edit = GraphEdit.new()
	graph_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(graph_edit)

func load_graph(graph: ConversationGraph):
	current_graph = graph
	_rebuild()

func _visual_for(node: Resource) -> Script:
	return VISUALS.get(node.get_class(), DEFAULT_VISUAL)

func _rebuild():
	for child in graph_edit.get_children():
		if child is GraphNode:
			child.free()
	node_by_id.clear()
	if current_graph == null:
		return

	for node in current_graph.nodes:
		node_by_id[node.id] = node

	for node in current_graph.nodes:
		var visual := _visual_for(node)
		var gnode := GraphNode.new()
		gnode.name = node.id
		gnode.title = "%s (%s)" % [node.get_class(), node.id]
		gnode.position_offset = node.editor_position
		var label := Label.new()
		label.text = visual.describe(node)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.custom_minimum_size = Vector2(220, 0)
		gnode.add_child(label)
		visual.configure_slots(gnode, node)
		graph_edit.add_child(gnode)
		gnode.reset_size()
		gnode.dragged.connect(_on_node_dragged.bind(node))

	for node in current_graph.nodes:
		for target_id in _visual_for(node).outgoing_ids(node):
			if target_id != "" and node_by_id.has(target_id):
				graph_edit.connect_node(node.id, 0, target_id, 0)

func _on_node_dragged(from: Vector2, to: Vector2, node: Resource) -> void:
	# Goes through EditorUndoRedoManager rather than setting the property
	# directly: this both gives Ctrl+Z/Ctrl+Y for node moves and properly
	# marks the resource dirty, so Ctrl+S (which calls _apply_changes() on
	# the plugin) actually has something to save. No direct disk write here.
	if plugin == null:
		node.editor_position = to
		return
	var undo_redo := plugin.get_undo_redo()
	undo_redo.create_action("Move %s" % node.id)
	undo_redo.add_do_property(node, "editor_position", to)
	undo_redo.add_undo_property(node, "editor_position", from)
	undo_redo.commit_action()

func _on_save_layout_pressed():
	if current_graph == null:
		return
	for node in current_graph.nodes:
		var gnode = graph_edit.get_node_or_null(NodePath(node.id))
		if gnode is GraphNode:
			node.editor_position = gnode.position_offset
	var err := ResourceSaver.save(current_graph, current_graph.resource_path)
	if err != OK:
		push_error("DialogueFlow: failed to save layout (%s)" % err)
	else:
		print("DialogueFlow: layout saved to ", current_graph.resource_path)
