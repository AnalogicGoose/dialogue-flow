## Base "interface" for a node type's editor-visual behavior: what its
## GraphNode body shows, what edges it exports, and how its slots are
## configured. One subclass per node type, mirroring dialogue-flow-rust's
## resources/*.rs split -- graph_editor.gd looks these up by class name
## instead of branching on node type itself.
class_name NodeVisual
extends RefCounted

static func describe(node: Resource) -> String:
	return ""

static func outgoing_ids(node: Resource) -> Array[String]:
	return []

# One row per logical outgoing connection, in the order they should be
# drawn (row index == connection port index, in graph_editor.gd's
# wire-drawing and connection-routing code). Each row is
# {"label": String, "target_id": String, "removable": bool}. Default
# wraps outgoing_ids() 1:1 with blank labels and nothing removable --
# preserves today's single-row behavior for every type that doesn't
# override this.
static func output_rows(node: Resource) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for target_id in outgoing_ids(node):
		rows.append({"label": "", "target_id": target_id, "removable": false})
	return rows

# Whether this node type supports adding/removing output rows from its
# own body (a trailing "+" button, and a trash icon on any row
# output_rows() marks removable). Default: no -- Inspector-only, as
# today, for anything that doesn't opt in.
static func supports_dynamic_pins() -> bool:
	return false

# Appends a new blank/unwired row. Returns the {property, value} patch to
# commit, or {} if not supported.
static func add_pin_patch(node: Resource) -> Dictionary:
	return {}

# Removes the row at `row_index` (only ever called on a row output_rows()
# marked "removable"). Returns the {property, value} patch to commit, or
# {} if not supported.
static func remove_pin_patch(node: Resource, row_index: int) -> Dictionary:
	return {}

# Configures slot 0 (the node's description/header row, which also
# doubles as its sole pin row when row_count <= 1). `row_count` is
# output_rows(node).size() -- when it's more than 1, row 0's output side
# is disabled here so each real output gets its own dedicated row instead
# (added generically by graph_editor.gd, one per output_rows() entry).
# GraphEdit numbers connection ports over enabled slots only, top to
# bottom, so disabling row 0's output when there are dedicated rows below
# it is what keeps port numbering lined up with output_rows() indices in
# both cases -- no separate offset bookkeeping needed anywhere.
static func configure_slots(gnode: GraphNode, node: Resource, row_count: int) -> void:
	gnode.set_slot(0, true, 0, Color.WHITE, row_count <= 1, 0, Color.WHITE)

static func color() -> Color:
	return Color(0.35, 0.35, 0.38)

static func can_connect_to(node: Resource, target: Resource, port: int = 0) -> bool:
	return not (target is EntryNode) and not (target is ResponseNode)

static func connection_patch(node: Resource, target: Resource, port: int = 0) -> Dictionary:
	return {"property": "next_id", "value": target.id}

static func disconnection_patch(node: Resource, target_id: String, port: int = 0) -> Dictionary:
	if node.get("next_id") == target_id:
		return {"property": "next_id", "value": ""}
	return {}

# Whether this node type could ever be a connection's source -- used to
# filter the pin-drag-to-empty-space node list when the drag started at an
# INPUT pin (the new node would need an output to feed into it).
static func can_be_source() -> bool:
	return true

# Rewrites this (already-duplicated) node's own outgoing edge fields via
# id_map (old id -> new id). A target not in id_map pointed outside the
# duplicated selection -- cleared, not left dangling or silently
# reconnected into the original graph.
static func remap_ids(node: Resource, id_map: Dictionary) -> void:
	pass
