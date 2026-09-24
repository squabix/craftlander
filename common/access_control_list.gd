class_name ACL
extends Resource

enum Mode { WHITE, BLACK, UNREGULATED }

@export var mode: Mode
@export var list: Array


static func resolve(source: ACL, entries: Array) -> ACL:
	if source == null:
		if not entries.is_empty():
			push_error("Cannot resolve entries %s without a source ACL (treating as unregulated)" % [entries])
		var acl := ACL.new()
		acl.mode = Mode.UNREGULATED
		return acl
	var resolved := source.duplicate() as ACL
	if not entries.is_empty():
		resolved.list = entries
	return resolved


func is_unrestricted() -> bool:
	return mode == Mode.UNREGULATED or list.is_empty()


func passes(...values: Array) -> bool:
	if is_unrestricted():
		return true
	var listed := false
	for value in values:
		if value in list:
			listed = true
			break
	return listed == (mode == Mode.WHITE)


func passes_groups(node: Node) -> bool:
	return passes.callv(node.get_groups())
