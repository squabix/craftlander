class_name Identification
extends Object

const DEFAULT_ID_PROPERTY: String = "id"

var _pool: Dictionary


func auto_register(node: Node) -> bool:
	if not is_instance_valid(node):
		printerr("Cannot auto register invalid node %s" % node)
		return false

	if not DEFAULT_ID_PROPERTY in node:
		printerr("Cannot auto register %s without default id property" % node)
		return false

	var id: Variant = node[DEFAULT_ID_PROPERTY]
	if not id is int:
		printerr("Cannot auto register %s with noninteger id property" % node)
		return false

	register(node, id)
	return true


func fetch(id: int) -> Variant:
	if not id in _pool:
		printerr("%s could not fetch id %s from pool %s" % [self, id, _pool])
		return null
	return _pool[id]


func is_registered(id: int) -> bool:
	return id in _pool


func register(a: Variant, id: int) -> void:
	_pool[id] = a


func unregister(id: int) -> void:
	_pool.erase(id)
