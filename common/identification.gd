extends Object
class_name Identification

const DEFAULT_ID_PROPERTY: String = "id"

var _pool: Dictionary

func auto_register(node: Node) -> bool:
	if not DEFAULT_ID_PROPERTY in node:
		return false
	
	var id: Variant = node[DEFAULT_ID_PROPERTY]
	if not id is int:
		return false
	
	register(node, id)
	return true

func fetch(id: int) -> Variant:
	if not id in _pool:
		return null
	return _pool[id]

func is_registered(id: int) -> bool:
	return id in _pool

func register(a: Variant, id: int) -> void:
	_pool[id] = a

func unregister(id: int) -> void:
	_pool.erase(id)
