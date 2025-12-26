extends Object
class_name Identification

const DEFAULT_ID_PROPERTY: String = "id"

var _pool: Dictionary

func auto_register(node: Node) -> bool:
	print("auto registering")
	if not is_instance_valid(node):
		printerr("Cannot auto register invalid node ", node)
		return false
	
	if not DEFAULT_ID_PROPERTY in node:
		printerr("Cannot auto register ", node, " without default id property")
		return false
	
	var id: Variant = node[DEFAULT_ID_PROPERTY]
	if not id is int:
		printerr("Cannot auto register ", node, " with noninteger id property")
		return false
	
	register(node, id)
	print("Success, ", _pool)
	return true

func fetch(id: int) -> Variant:
	print("Fetching ", id)
	if not id in _pool:
		return null
	return _pool[id]

func is_registered(id: int) -> bool:
	return id in _pool

func register(a: Variant, id: int) -> void:
	_pool[id] = a

func unregister(id: int) -> void:
	_pool.erase(id)
