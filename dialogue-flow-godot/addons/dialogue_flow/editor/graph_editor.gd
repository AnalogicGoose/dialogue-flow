@tool
extends Control

var graph_edit: GraphEdit
var current_graph: ConversationGraph
var node_by_id: Dictionary = {}

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	graph_edit = GraphEdit.new()
	graph_edit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	graph_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(graph_edit)

func load_graph(graph: ConversationGraph):
	current_graph = graph
	_rebuild()

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
		var gnode := GraphNode.new()
		gnode.name = node.id
		gnode.title = "%s (%s)" % [node.get_class(), node.id]
		gnode.position_offset = node.editor_position
		var label := Label.new()
		label.text = _describe(node)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.custom_minimum_size = Vector2(220, 0)
		gnode.add_child(label)
		_configure_slots(gnode, node)
		graph_edit.add_child(gnode)
		gnode.reset_size()

	for node in current_graph.nodes:
		for target_id in _outgoing_ids(node):
			if target_id != "" and node_by_id.has(target_id):
				graph_edit.connect_node(node.id, 0, target_id, 0)

func _configure_slots(gnode: GraphNode, node: Resource) -> void:
	var has_input := not (node is EntryNode)
	var has_output := not (node is EndNode or node is RestartNode)
	gnode.set_slot(0, has_input, 0, Color.WHITE, has_output, 0, Color.WHITE)

func _describe(node: Resource) -> String:
	if node is SpeechNode:
		return "%s: %s" % [node.speaker, node.text]
	elif node is ResponseNode:
		return node.text
	elif node is EventNode:
		return str(node.event_name)
	elif node is ConditionNode:
		return str(node.variable_name)
	return ""

func _outgoing_ids(node: Resource) -> Array[String]:
	var ids: Array[String] = []
	if node is EntryNode or node is ResponseNode or node is EventNode or node is RerouteNode or node is WaitForEventNode:
		ids.append(node.next_id)
	elif node is SpeechNode:
		ids.append_array(node.response_ids)
		if node.fallback_id != "":
			ids.append(node.fallback_id)
	elif node is ConditionNode:
		ids.append(node.true_id)
		ids.append(node.false_id)
	elif node is RandomNode:
		for b in node.branches:
			ids.append(b.target_id)
	return ids
