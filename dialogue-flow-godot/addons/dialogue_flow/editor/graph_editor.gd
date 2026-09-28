@tool
extends Control

const LAYER_SPACING_X := 400.0
const NODE_SPACING_Y := 40.0

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

	var layer_of := _compute_layers()

	var gnodes: Dictionary = {}
	for node in current_graph.nodes:
		var gnode := GraphNode.new()
		gnode.name = node.id
		gnode.title = "%s (%s)" % [node.get_class(), node.id]
		var label := Label.new()
		label.text = _describe(node)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.custom_minimum_size = Vector2(220, 0)
		gnode.add_child(label)
		_configure_slots(gnode, node)
		graph_edit.add_child(gnode)
		gnode.reset_size()
		gnodes[node.id] = gnode

	var next_y_by_layer: Dictionary = {}
	for node in current_graph.nodes:
		var gnode: GraphNode = gnodes[node.id]
		if node.editor_position != Vector2.ZERO:
			gnode.position_offset = node.editor_position
			continue
		var layer: int = layer_of.get(node.id, 0)
		var y: float = next_y_by_layer.get(layer, 0.0)
		gnode.position_offset = Vector2(layer * LAYER_SPACING_X, y)
		next_y_by_layer[layer] = y + gnode.size.y + NODE_SPACING_Y

	for node in current_graph.nodes:
		for target_id in _outgoing_ids(node):
			if target_id != "" and node_by_id.has(target_id):
				graph_edit.connect_node(node.id, 0, target_id, 0)

func _configure_slots(gnode: GraphNode, node: Resource) -> void:
	var has_input := not (node is EntryNode)
	var has_output := not (node is EndNode or node is RestartNode)
	gnode.set_slot(0, has_input, 0, Color.WHITE, has_output, 0, Color.WHITE)

func _compute_layers() -> Dictionary:
	var entry_id := ""
	var end_ids: Array[String] = []
	for node in current_graph.nodes:
		if node is EntryNode:
			entry_id = node.id
		elif node is EndNode:
			end_ids.append(node.id)

	var layer_of: Dictionary = {}
	if entry_id == "":
		return layer_of

	var on_path: Dictionary = {}
	_dfs_layer(entry_id, 0, layer_of, on_path)

	var max_layer := 0
	for l in layer_of.values():
		max_layer = max(max_layer, l)
	var end_layer := max_layer + 1
	for end_id in end_ids:
		if layer_of.has(end_id):
			layer_of[end_id] = end_layer
	if not end_ids.is_empty():
		max_layer = end_layer

	var unreached_layer := max_layer + 1
	for node in current_graph.nodes:
		if not layer_of.has(node.id):
			layer_of[node.id] = unreached_layer

	return layer_of

# Assigns each node the longest acyclic path length found from Entry.
# A target already on the current path (on_path) is a genuine cycle
# back-edge (via Restart, or a Response looping back) -- skipped, so a
# cycle can never push its own ancestor further right without bound.
# A target reached again via a *longer* independent path (convergence,
# not a cycle) still gets its layer updated upward, which is what lets
# End/merge points sit after the longest branch reaching them.
func _dfs_layer(id: String, depth: int, layer_of: Dictionary, on_path: Dictionary) -> void:
	if on_path.has(id):
		return
	if layer_of.has(id) and layer_of[id] >= depth:
		return
	layer_of[id] = depth

	on_path[id] = true
	var node = node_by_id.get(id)
	if node != null:
		for target_id in _outgoing_ids(node):
			if target_id != "" and node_by_id.has(target_id):
				_dfs_layer(target_id, depth + 1, layer_of, on_path)
	on_path.erase(id)

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
