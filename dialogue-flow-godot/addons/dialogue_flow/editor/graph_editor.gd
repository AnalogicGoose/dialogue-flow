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
const DialogueGraphEdit := preload("res://addons/dialogue_flow/editor/dialogue_graph_edit.gd")

const NODE_TYPES := [
	{"label": "Entry", "class": "EntryNode", "prefix": "entry"},
	{"label": "Speech", "class": "SpeechNode", "prefix": "speech"},
	{"label": "Response", "class": "ResponseNode", "prefix": "response"},
	{"label": "Event", "class": "EventNode", "prefix": "event"},
	{"label": "Condition", "class": "ConditionNode", "prefix": "condition"},
	{"label": "Random", "class": "RandomNode", "prefix": "random"},
	{"label": "Wait For Event", "class": "WaitForEventNode", "prefix": "wait_for_event"},
	{"label": "Reroute", "class": "RerouteNode", "prefix": "reroute"},
	{"label": "Restart", "class": "RestartNode", "prefix": "restart"},
	{"label": "End", "class": "EndNode", "prefix": "end"},
]

var plugin: EditorPlugin
var graph_edit: DialogueGraphEdit
var empty_label: Label
var close_confirm: ConfirmationDialog
var nodes_button: Button
var current_graph: ConversationGraph
var node_by_id: Dictionary = {}
var pending_create_position: Vector2
var pending_selection_ids: Array[String] = []
# Nodes captured by copy_selected_nodes(), already duplicate(true)'d at
# copy time so later edits to the originals don't leak into the buffer.
# Their own `id` fields are left untouched -- paste_nodes() only needs
# them to stay internally consistent with each other, to remap edges
# between pasted nodes the same way duplication does.
var clipboard_nodes: Array[Resource] = []
# True once current_graph has any change committed through
# _apply_entries_and_rebuild since it was last loaded or saved. Drives the
# "unsaved changes" prompt on Close -- separate from Godot's own tab-dirty
# asterisk, which we don't have a reliable read on from here.
var dirty: bool = false

var create_popup: PopupPanel
var create_search: LineEdit
var create_list: ItemList
var filtered_node_types: Array[int] = []
# Set only when the create popup was opened by dragging a pin into empty
# space: the popup then both creates the picked node AND wires the
# connection, and the list is filtered to types compatible with this pin.
var pending_pin_node: Resource = null
var pending_pin_reverse: bool = false
var pending_pin_port: int = 0

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var toolbar := HBoxContainer.new()
	vbox.add_child(toolbar)
	toolbar.add_child(_toolbar_button("New", "New Graph", _on_new_pressed))
	toolbar.add_child(_toolbar_button("Load", "Open Graph", _on_open_pressed))
	toolbar.add_child(_toolbar_button("Save", "Save Layout", _on_save_layout_pressed))
	nodes_button = _toolbar_button("Add", "Add Node", _on_nodes_button_pressed)
	toolbar.add_child(nodes_button)
	toolbar.add_child(_toolbar_button("Close", "Close Graph", _on_close_pressed))

	# Plain Control, not another Container: graph_edit and empty_label both
	# fill it via PRESET_FULL_RECT and overlap freely as siblings. Needed
	# because GraphEdit applies its own pan/zoom transform to its own
	# children -- a Label added directly under graph_edit inherited that
	# transform instead of staying docked to the visible viewport, which is
	# why it never showed up.
	var canvas_area := Control.new()
	canvas_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(canvas_area)

	graph_edit = DialogueGraphEdit.new()
	graph_edit.editor = self
	graph_edit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	graph_edit.right_disconnects = true
	graph_edit.popup_request.connect(_on_graph_popup_request)
	graph_edit.delete_nodes_request.connect(_on_delete_nodes_request)
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	graph_edit.connection_to_empty.connect(_on_connection_to_empty)
	graph_edit.connection_from_empty.connect(_on_connection_from_empty)
	canvas_area.add_child(graph_edit)

	empty_label = Label.new()
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty_label.modulate = Color(1, 1, 1, 0.5)
	canvas_area.add_child(empty_label)

	close_confirm = ConfirmationDialog.new()
	close_confirm.dialog_text = "This graph has unsaved changes. Save before closing?"
	close_confirm.ok_button_text = "Save"
	close_confirm.add_button("Discard", false, "discard")
	close_confirm.confirmed.connect(_on_close_confirm_save)
	close_confirm.custom_action.connect(_on_close_confirm_custom_action)
	add_child(close_confirm)

	create_popup = PopupPanel.new()
	var popup_vbox := VBoxContainer.new()
	create_popup.add_child(popup_vbox)
	create_search = LineEdit.new()
	create_search.placeholder_text = "Search node type..."
	create_search.custom_minimum_size = Vector2(220, 0)
	create_search.text_changed.connect(_on_create_search_changed)
	create_search.text_submitted.connect(_on_create_search_submitted)
	create_search.gui_input.connect(_on_create_search_gui_input)
	popup_vbox.add_child(create_search)
	create_list = ItemList.new()
	create_list.custom_minimum_size = Vector2(220, 160)
	create_list.item_activated.connect(_on_create_list_item_activated)
	popup_vbox.add_child(create_list)
	add_child(create_popup)

	# Without this, current_graph stays null until load_graph()/close are
	# called, and empty_label keeps its default empty text -- present but
	# invisible -- until then. This primes the "no graph open" state right
	# from plugin startup.
	_rebuild()

func _toolbar_button(icon_name: String, tooltip: String, callback: Callable) -> Button:
	var button := Button.new()
	button.icon = EditorInterface.get_editor_theme().get_icon(icon_name, "EditorIcons")
	button.tooltip_text = tooltip
	button.flat = true
	button.pressed.connect(callback)
	return button

func load_graph(graph: ConversationGraph):
	current_graph = graph
	dirty = false
	_rebuild()

func _visual_for(node: Resource) -> Script:
	return VISUALS.get(node.get_class(), DEFAULT_VISUAL)

func _rebuild():
	for child in graph_edit.get_children():
		if child is GraphNode:
			child.free()
	node_by_id.clear()
	if current_graph == null:
		empty_label.text = "No graph open -- use New or Open above"
		empty_label.visible = true
		return

	for node in current_graph.nodes:
		node_by_id[node.id] = node

	if current_graph.nodes.is_empty():
		empty_label.text = "This graph is empty -- right-click the canvas or use Add Node"
		empty_label.visible = true
		return
	empty_label.visible = false

	var validation: Dictionary = current_graph.validate()

	for node in current_graph.nodes:
		var visual := _visual_for(node)
		var gnode := GraphNode.new()
		gnode.name = node.id
		gnode.title = "%s (%s)" % [node.get_class(), node.id]
		if node is EntryNode:
			gnode.title = "▶ " + gnode.title
		gnode.position_offset = node.editor_position

		var titlebar_style := StyleBoxFlat.new()
		titlebar_style.bg_color = visual.color()
		titlebar_style.content_margin_left = 8
		titlebar_style.content_margin_right = 8
		titlebar_style.content_margin_top = 4
		titlebar_style.content_margin_bottom = 4
		gnode.add_theme_stylebox_override("titlebar", titlebar_style)
		var titlebar_selected_style := titlebar_style.duplicate()
		titlebar_selected_style.bg_color = visual.color().lightened(0.3)
		gnode.add_theme_stylebox_override("titlebar_selected", titlebar_selected_style)

		var label := Label.new()
		label.text = visual.describe(node)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.custom_minimum_size = Vector2(220, 0)
		gnode.add_child(label)

		var status := _validation_status_for(node.id, validation)
		if not status["errors"].is_empty() or not status["warnings"].is_empty():
			var parts: Array[String] = []
			if not status["errors"].is_empty():
				parts.append("✗ %d error(s)" % status["errors"].size())
			if not status["warnings"].is_empty():
				parts.append("⚠ %d warning(s)" % status["warnings"].size())
			var status_label := Label.new()
			status_label.text = "  /  ".join(parts)
			status_label.modulate = Color.RED if not status["errors"].is_empty() else Color(1.0, 0.8, 0.2)
			gnode.add_child(status_label)
			var tooltip_lines: Array[String] = []
			tooltip_lines.append_array(status["errors"])
			tooltip_lines.append_array(status["warnings"])
			gnode.tooltip_text = "\n".join(tooltip_lines)

		# One row per logical outgoing connection (Unreal Blueprint /
		# Orchestrator style), instead of every connection sharing slot 0's
		# single pin. Row 0 (the description label above) keeps its output
		# only when there's just one row total; otherwise it becomes
		# input-only and every row here gets its own dedicated, port-numbered
		# output slot. See the roadmap's "Planned: Graph Node Visual System
		# Refactor" section for the full design writeup.
		var rows: Array[Dictionary] = visual.output_rows(node)
		visual.configure_slots(gnode, node, rows.size())

		if rows.size() > 1:
			for i in rows.size():
				var row_data: Dictionary = rows[i]
				var row_box := HBoxContainer.new()
				var row_label := Label.new()
				row_label.text = row_data.get("label", "")
				row_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row_box.add_child(row_label)
				if row_data.get("removable", false):
					var remove_button := Button.new()
					remove_button.icon = EditorInterface.get_editor_theme().get_icon("Remove", "EditorIcons")
					remove_button.flat = true
					remove_button.tooltip_text = "Remove this pin"
					remove_button.pressed.connect(_on_remove_pin_pressed.bind(node, i))
					row_box.add_child(remove_button)
				gnode.add_child(row_box)
				gnode.set_slot(gnode.get_child_count() - 1, false, 0, Color.WHITE, true, 0, Color.WHITE)

		if visual.supports_dynamic_pins():
			var add_button := Button.new()
			add_button.icon = EditorInterface.get_editor_theme().get_icon("Add", "EditorIcons")
			add_button.text = "Add Pin"
			add_button.flat = true
			add_button.pressed.connect(_on_add_pin_pressed.bind(node))
			gnode.add_child(add_button)

		graph_edit.add_child(gnode)
		gnode.reset_size()
		gnode.dragged.connect(_on_node_dragged.bind(node))
		gnode.node_selected.connect(_on_node_selected.bind(node))
		if not node.changed.is_connected(_on_node_resource_changed):
			node.changed.connect(_on_node_resource_changed)

	for node in current_graph.nodes:
		var rows: Array[Dictionary] = _visual_for(node).output_rows(node)
		for i in rows.size():
			var target_id: String = rows[i]["target_id"]
			if target_id != "" and node_by_id.has(target_id):
				graph_edit.connect_node(node.id, i, target_id, 0)

	if not pending_selection_ids.is_empty():
		for gnode in graph_edit.get_children():
			if gnode is GraphNode:
				gnode.selected = gnode.name in pending_selection_ids
		pending_selection_ids = []

func _validation_status_for(node_id: String, validation: Dictionary) -> Dictionary:
	var needle := "'%s'" % node_id
	var errors: Array[String] = []
	var warnings: Array[String] = []
	for e in validation.get("errors", []):
		if String(e).contains(needle):
			errors.append(String(e))
	for w in validation.get("warnings", []):
		if String(w).contains(needle):
			warnings.append(String(w))
	return {"errors": errors, "warnings": warnings}

func is_connection_valid(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> bool:
	var source: Resource = node_by_id.get(String(from_node))
	var target: Resource = node_by_id.get(String(to_node))
	if source == null or target == null:
		return false
	return _visual_for(source).can_connect_to(source, target, from_port)

func _on_node_dragged(from: Vector2, to: Vector2, node: Resource) -> void:
	_commit_property_change("Move %s" % node.id, node, "editor_position", to)

func _on_node_resource_changed() -> void:
	dirty = true
	call_deferred("_rebuild")

func _on_node_selected(node: Resource) -> void:
	EditorInterface.edit_resource(node)

# DisplayServer.mouse_get_position() / Control.get_local_mouse_position() are
# both queried fresh, right when the signal fires, instead of trusting
# popup_request()'s own `at_position` argument -- its coordinate space isn't
# clearly documented and trusting it once already put the popup in the wrong
# spot. Querying the mouse directly sidesteps that ambiguity entirely.
func _on_graph_popup_request(_at_position: Vector2) -> void:
	if current_graph == null:
		return
	var screen_pos := DisplayServer.mouse_get_position()
	var graph_pos := _graph_local_to_position_offset(graph_edit.get_local_mouse_position())
	_open_create_popup(screen_pos, graph_pos)

func _on_nodes_button_pressed() -> void:
	if current_graph == null:
		return
	var screen_pos: Vector2 = nodes_button.get_screen_position() + Vector2(0, nodes_button.size.y + 2)
	var graph_pos := _graph_local_to_position_offset(graph_edit.size / 2.0)
	_open_create_popup(screen_pos, graph_pos)

# Dragging a wire from an OUTPUT pin and releasing over empty canvas: the
# dragged-from node becomes the source, the picked type becomes a brand new
# target node, created and connected in one step.
func _on_connection_to_empty(from_node: StringName, from_port: int, _release_position: Vector2) -> void:
	if current_graph == null:
		return
	var source: Resource = node_by_id.get(String(from_node))
	if source == null:
		return
	var screen_pos := DisplayServer.mouse_get_position()
	var graph_pos := _graph_local_to_position_offset(graph_edit.get_local_mouse_position())
	_open_create_popup(screen_pos, graph_pos, source, false, from_port)

# Dragging a wire from an INPUT pin and releasing over empty canvas: the
# dragged-from node becomes the target, the picked type becomes a brand new
# source node feeding into it.
func _on_connection_from_empty(to_node: StringName, _to_port: int, _release_position: Vector2) -> void:
	if current_graph == null:
		return
	var target: Resource = node_by_id.get(String(to_node))
	if target == null:
		return
	var screen_pos := DisplayServer.mouse_get_position()
	var graph_pos := _graph_local_to_position_offset(graph_edit.get_local_mouse_position())
	_open_create_popup(screen_pos, graph_pos, target, true)

# GraphNode.position_offset / editor_position are in unscaled graph space;
# a click position is in on-screen widget pixels. scroll_offset shifts the
# origin, zoom scales it -- this is the inverse of GraphEdit's own layout
# transform, so newly created nodes land where the user actually clicked
# regardless of current pan/zoom.
func _graph_local_to_position_offset(local_pos: Vector2) -> Vector2:
	return (local_pos + graph_edit.scroll_offset) / graph_edit.zoom

func _open_create_popup(screen_position: Vector2, graph_position: Vector2, pin_node: Resource = null, pin_reverse: bool = false, pin_port: int = 0) -> void:
	pending_create_position = graph_position
	pending_pin_node = pin_node
	pending_pin_reverse = pin_reverse
	pending_pin_port = pin_port
	create_search.text = ""
	_refresh_create_list("")
	create_popup.position = screen_position
	create_popup.popup()
	create_search.call_deferred("grab_focus")

func _refresh_create_list(filter: String) -> void:
	create_list.clear()
	filtered_node_types.clear()
	var needle := filter.to_lower()
	for i in NODE_TYPES.size():
		if pending_pin_node != null and not _type_compatible_with_pin(i):
			continue
		var label: String = NODE_TYPES[i]["label"]
		if needle == "" or label.to_lower().contains(needle):
			create_list.add_item(label)
			filtered_node_types.append(i)
	if create_list.item_count > 0:
		create_list.select(0)

# pending_pin_reverse == false: pending_pin_node is the SOURCE, candidate
# types are judged as its target (does pending_pin_node's own visual accept
# an instance of this type?).
# pending_pin_reverse == true: pending_pin_node is the TARGET, candidate
# types are judged as the source -- they need an output at all
# (can_be_source) and must accept pending_pin_node as their target.
func _type_compatible_with_pin(type_index: int) -> bool:
	var type_info: Dictionary = NODE_TYPES[type_index]
	var visual: Script = VISUALS.get(type_info["class"], DEFAULT_VISUAL)
	var probe: Resource = ClassDB.instantiate(type_info["class"])
	if pending_pin_reverse:
		return visual.can_be_source() and visual.can_connect_to(probe, pending_pin_node)
	return _visual_for(pending_pin_node).can_connect_to(pending_pin_node, probe, pending_pin_port)

func _on_create_search_changed(text: String) -> void:
	_refresh_create_list(text)

func _on_create_search_submitted(_text: String) -> void:
	_confirm_create_selection()

# LineEdit keeps focus the whole time (so typing always works), so Up/Down
# have to be intercepted here and applied to create_list manually -- they'd
# otherwise just be swallowed (or move the caret) instead of changing which
# item Enter/text_submitted would pick.
func _on_create_search_gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	if event.keycode == KEY_DOWN:
		_move_create_selection(1)
		create_search.accept_event()
	elif event.keycode == KEY_UP:
		_move_create_selection(-1)
		create_search.accept_event()

func _move_create_selection(delta: int) -> void:
	if create_list.item_count == 0:
		return
	var selected := create_list.get_selected_items()
	var current: int = selected[0] if not selected.is_empty() else -1
	var next: int = clampi(current + delta, 0, create_list.item_count - 1)
	create_list.select(next)
	create_list.ensure_current_is_visible()

func _on_create_list_item_activated(_index: int) -> void:
	_confirm_create_selection()

func _confirm_create_selection() -> void:
	if create_list.item_count == 0:
		return
	var selected := create_list.get_selected_items()
	var list_index: int = selected[0] if not selected.is_empty() else 0
	var type_index: int = filtered_node_types[list_index]
	create_popup.hide()
	if pending_pin_node != null:
		_create_and_connect(type_index, pending_create_position, pending_pin_node, pending_pin_reverse, pending_pin_port)
		pending_pin_node = null
	else:
		_create_node(type_index, pending_create_position)

func _create_node(type_index: int, at_position: Vector2) -> void:
	if current_graph == null:
		return
	var type_info: Dictionary = NODE_TYPES[type_index]
	var new_node: Resource = ClassDB.instantiate(type_info["class"])
	new_node.id = _generate_unique_id(type_info["prefix"])
	new_node.editor_position = at_position
	var new_nodes: Array[Resource] = current_graph.nodes.duplicate()
	new_nodes.append(new_node)
	_commit_property_change("Create %s" % type_info["label"], current_graph, "nodes", new_nodes)

# Creates the picked node AND wires it to the node the drag started from, as
# one undoable step. `reverse` decides which end pending_pin_node fills --
# see _type_compatible_with_pin for the same source/target reasoning.
func _create_and_connect(type_index: int, at_position: Vector2, pinned_node: Resource, reverse: bool, pin_port: int) -> void:
	if current_graph == null:
		return
	var type_info: Dictionary = NODE_TYPES[type_index]
	var new_node: Resource = ClassDB.instantiate(type_info["class"])
	new_node.id = _generate_unique_id(type_info["prefix"])
	new_node.editor_position = at_position

	var source: Resource = new_node if reverse else pinned_node
	var target: Resource = pinned_node if reverse else new_node
	# reverse: the new node is the source, always at its own port 0 (its
	# first connection). Otherwise the drag started at pinned_node's own
	# pin_port, which is what decides which of its rows gets wired.
	var source_port: int = 0 if reverse else pin_port
	var patch: Dictionary = _visual_for(source).connection_patch(source, target, source_port)

	var new_nodes: Array[Resource] = current_graph.nodes.duplicate()
	new_nodes.append(new_node)

	var do_entries: Array = [[current_graph, "nodes", new_nodes]]
	var undo_entries: Array = [[current_graph, "nodes", current_graph.nodes.duplicate()]]
	if not patch.is_empty():
		do_entries.append([source, patch["property"], patch["value"]])
		undo_entries.append([source, patch["property"], source.get(patch["property"])])

	_commit_multi_change("Create %s" % type_info["label"], do_entries, undo_entries)

func _on_delete_nodes_request(node_names: Array[StringName]) -> void:
	if current_graph == null:
		return
	var to_delete := {}
	for n in node_names:
		to_delete[String(n)] = true
	var new_nodes: Array[Resource] = []
	for node in current_graph.nodes:
		if not to_delete.has(node.id):
			new_nodes.append(node)
	_commit_property_change("Delete %d node(s)" % node_names.size(), current_graph, "nodes", new_nodes)

func _get_selected_resource_nodes() -> Array[Resource]:
	var result: Array[Resource] = []
	for child in graph_edit.get_children():
		if child is GraphNode and child.selected:
			var node: Resource = node_by_id.get(String(child.name))
			if node != null:
				result.append(node)
	return result

func duplicate_selected_nodes() -> void:
	var originals := _get_selected_resource_nodes()
	if originals.is_empty():
		return
	_clone_and_commit(
		originals,
		func(o: Resource) -> Vector2: return o.editor_position + Vector2(40, 40),
		"Duplicate %d node(s)" % originals.size()
	)

func copy_selected_nodes() -> void:
	var originals := _get_selected_resource_nodes()
	if originals.is_empty():
		return
	var buffer: Array[Resource] = []
	for node in originals:
		buffer.append(node.duplicate(true))
	clipboard_nodes = buffer

func paste_nodes() -> void:
	if current_graph == null or clipboard_nodes.is_empty():
		return
	var centroid := Vector2.ZERO
	for node in clipboard_nodes:
		centroid += node.editor_position
	centroid /= clipboard_nodes.size()
	var paste_anchor := _graph_local_to_position_offset(graph_edit.get_local_mouse_position())
	_clone_and_commit(
		clipboard_nodes,
		func(o: Resource) -> Vector2: return o.editor_position - centroid + paste_anchor,
		"Paste %d node(s)" % clipboard_nodes.size()
	)

# Shared by duplicate and paste: clone each source Resource (deep, so
# sub-resources like RandomBranch aren't shared with the source), give
# each a freshly generated id, remap edges internal to this batch to the
# new ids (clearing anything that pointed outside it), then commit the
# whole thing as one atomic undo/redo step and leave the clones selected.
# `position_for` maps each source to its clone's editor_position.
func _clone_and_commit(sources: Array[Resource], position_for: Callable, action_label: String) -> void:
	if current_graph == null or sources.is_empty():
		return

	var id_map: Dictionary = {}
	var clones: Array[Resource] = []
	for source in sources:
		var dup: Resource = source.duplicate(true)
		var new_id := _generate_unique_id(_prefix_for_class(dup.get_class()))
		node_by_id[new_id] = dup # reserved for this batch; overwritten by the next _rebuild()
		id_map[source.id] = new_id
		dup.id = new_id
		dup.editor_position = position_for.call(source)
		clones.append(dup)

	for dup in clones:
		_visual_for(dup).remap_ids(dup, id_map)

	var new_nodes: Array[Resource] = current_graph.nodes.duplicate()
	new_nodes.append_array(clones)
	var new_selection_ids: Array[String] = []
	for dup in clones:
		new_selection_ids.append(dup.id)
	pending_selection_ids = new_selection_ids
	_commit_multi_change(
		action_label,
		[[current_graph, "nodes", new_nodes]],
		[[current_graph, "nodes", current_graph.nodes.duplicate()]]
	)

func _prefix_for_class(node_class: String) -> String:
	for type_info in NODE_TYPES:
		if type_info["class"] == node_class:
			return type_info["prefix"]
	return node_class.to_lower()

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var source: Resource = node_by_id.get(String(from_node))
	var target: Resource = node_by_id.get(String(to_node))
	if source == null or target == null:
		return
	var visual := _visual_for(source)
	if not visual.can_connect_to(source, target, from_port):
		push_warning("DialogueFlow: '%s' cannot connect to '%s' this way yet -- use the Inspector" % [from_node, to_node])
		return
	var patch: Dictionary = visual.connection_patch(source, target, from_port)
	if patch.is_empty():
		return
	_commit_property_change("Connect %s -> %s" % [from_node, to_node], source, patch["property"], patch["value"])

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var source: Resource = node_by_id.get(String(from_node))
	if source == null:
		return
	var patch: Dictionary = _visual_for(source).disconnection_patch(source, String(to_node), from_port)
	if patch.is_empty():
		return
	_commit_property_change("Disconnect %s -> %s" % [from_node, to_node], source, patch["property"], patch["value"])

func _on_add_pin_pressed(node: Resource) -> void:
	var patch: Dictionary = _visual_for(node).add_pin_patch(node)
	if patch.is_empty():
		return
	_commit_property_change("Add pin to %s" % node.id, node, patch["property"], patch["value"])

func _on_remove_pin_pressed(node: Resource, row_index: int) -> void:
	var patch: Dictionary = _visual_for(node).remove_pin_patch(node, row_index)
	if patch.is_empty():
		return
	_commit_property_change("Remove pin from %s" % node.id, node, patch["property"], patch["value"])

func _generate_unique_id(prefix: String) -> String:
	var i := 1
	while node_by_id.has("%s_%d" % [prefix, i]):
		i += 1
	return "%s_%d" % [prefix, i]

# Every structural edit (position, connections, node create/delete) goes
# through here so it's uniformly Ctrl+Z/Ctrl+Y-able via EditorUndoRedoManager
# and marks the resource dirty for Ctrl+S (_apply_changes() on the plugin).
func _commit_property_change(label: String, object: Object, property: String, new_value) -> void:
	var old_value = object.get(property)
	_commit_multi_change(label, [[object, property, new_value]], [[object, property, old_value]])

# General form of the above for edits that touch more than one object as a
# single undo step (e.g. create-a-node-and-connect-it-to-a-dragged-pin).
# do/undo are each ONE method call applying every [object, property, value]
# entry then rebuilding once, rather than one add_do_property/add_do_method
# pair per entry -- with several entries in one UndoRedo action, the order
# multiple do/undo methods actually run in isn't something to bet a correct
# rebuild on, so each side stays a single atomic call.
func _commit_multi_change(label: String, do_entries: Array, undo_entries: Array) -> void:
	if plugin == null:
		_apply_entries_and_rebuild(do_entries)
		return
	var undo_redo := plugin.get_undo_redo()
	undo_redo.create_action(label)
	undo_redo.add_do_method(self, "_apply_entries_and_rebuild", do_entries)
	undo_redo.add_undo_method(self, "_apply_entries_and_rebuild", undo_entries)
	undo_redo.commit_action()

func _apply_entries_and_rebuild(entries: Array) -> void:
	for entry in entries:
		entry[0].set(entry[1], entry[2])
	dirty = true
	# Deferred: this often runs synchronously from inside a signal that
	# graph_edit or one of its GraphNode children is still emitting (dragged,
	# connection_to_empty, ...). _rebuild() immediately free()s old
	# GraphNodes, and Godot refuses to free a node while it (or an ancestor)
	# is mid-signal-dispatch ("Object is locked"). Deferring runs it after
	# that call stack unwinds, once nothing is locked anymore. Data above is
	# still set synchronously -- only the visual rebuild is delayed.
	call_deferred("_rebuild")

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
		dirty = false
		print("DialogueFlow: layout saved to ", current_graph.resource_path)

# Called by the plugin after a successful Ctrl+S save (_apply_changes()),
# which saves current_graph directly rather than through
# _on_save_layout_pressed().
func mark_saved() -> void:
	dirty = false

func _on_new_pressed() -> void:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.add_filter("*.tres", "Conversation Graph")
	dialog.current_path = "res://new_graph.tres"
	_popup_file_dialog(dialog, _create_new_graph_at)

func _create_new_graph_at(path: String) -> void:
	var graph := ConversationGraph.new()
	var entry: Resource = ClassDB.instantiate("EntryNode")
	entry.id = "entry_1"
	entry.editor_position = Vector2(80, 80)
	graph.nodes = [entry]
	var err := ResourceSaver.save(graph, path)
	if err != OK:
		push_error("DialogueFlow: failed to create new graph (%s)" % err)
		return
	EditorInterface.get_resource_filesystem().scan()
	_open_graph(load(path))

func _on_open_pressed() -> void:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.add_filter("*.tres", "Conversation Graph")
	_popup_file_dialog(dialog, _open_graph_at)

func _open_graph_at(path: String) -> void:
	var graph: ConversationGraph = load(path)
	if graph == null:
		push_error("DialogueFlow: failed to open '%s'" % path)
		return
	_open_graph(graph)

# Routed through EditorInterface.edit_resource() rather than calling
# load_graph() ourselves: that's what actually triggers the plugin's own
# _handles()/_edit() hooks (same path as double-clicking the resource in the
# FileSystem dock), so the main screen switches to this plugin and
# plugin.current_graph stays in sync for _apply_changes()/Ctrl+S.
func _open_graph(graph: ConversationGraph) -> void:
	EditorInterface.edit_resource(graph)

func _popup_file_dialog(dialog: EditorFileDialog, on_selected: Callable) -> void:
	add_child(dialog)
	dialog.file_selected.connect(func(path):
		on_selected.call(path)
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered_ratio()

func _on_close_pressed() -> void:
	if current_graph == null:
		return
	if dirty:
		close_confirm.popup_centered()
	else:
		_do_close()

func _on_close_confirm_save() -> void:
	_on_save_layout_pressed()
	_do_close()

func _on_close_confirm_custom_action(action: String) -> void:
	if action == "discard":
		close_confirm.hide()
		_do_close()

func _do_close() -> void:
	current_graph = null
	if plugin:
		plugin.current_graph = null
	dirty = false
	_rebuild()
