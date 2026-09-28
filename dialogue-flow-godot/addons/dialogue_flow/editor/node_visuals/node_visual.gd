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
