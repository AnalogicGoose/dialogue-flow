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

static func configure_slots(gnode: GraphNode, node: Resource) -> void:
	gnode.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)

static func color() -> Color:
	return Color(0.35, 0.35, 0.38)

static func can_connect_to(node: Resource, target: Resource) -> bool:
	return not (target is EntryNode) and not (target is ResponseNode)

static func connection_patch(node: Resource, target: Resource) -> Dictionary:
	return {"property": "next_id", "value": target.id}

static func disconnection_patch(node: Resource, target_id: String) -> Dictionary:
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
