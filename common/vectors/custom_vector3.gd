class_name CustomVector3
extends Object

var x: Variant
var y: Variant
var z: Variant


static func is_valid(v: Variant) -> bool:
	if v is Vector3 or v is Vector3i:
		return true
	if v is Object:
		return "x" in v and "y" in v and "z" in v
	return false


static func from(v: Variant) -> CustomVector3:
	if not v.is_valid():
		return null
	return CustomVector3.new(v.x, v.y, v.z)


func _init(custom_x: Variant = null, custom_y: Variant = null, custom_z: Variant = null) -> void:
	x = custom_x
	y = custom_y
	z = custom_z


func _to_string() -> String:
	return "(" + str(x) + ", " + str(y) + ", " + str(z) + ")"


func find(a: Variant) -> Vector3i:
	if x == a:
		return Util.VECTOR3X
	if y == a:
		return Util.VECTOR3Y
	if z == a:
		return Util.VECTOR3Z
	return Vector3i.ZERO


func as_array() -> Array:
	return [x, y, z]


func default(to: Variant) -> CustomVector3:
	if x == null:
		x = to
	if y == null:
		y = to
	if z == null:
		z = to
	return self


func contains(a: Variant) -> bool:
	return x == a or y == a or z == a


func classify() -> Variant:
	if x is float and y is float and z is float:
		return Vector3(x, y, z)
	if x is int and y is int and z is int:
		return Vector3i(x, y, z)
	if x is bool and y is bool and z is bool:
		return BoolVector3.construct(x, y, z)
	if x is Callable and y is Callable and z is Callable:
		return CallableVector3.new(x, y, z)
	if x is Array and y is Array and z is Array:
		return ArrayVector3.new(x, y, z)
	return self
