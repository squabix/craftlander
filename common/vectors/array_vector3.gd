extends Object
class_name ArrayVector3

var x: Array
var y: Array
var z: Array

func _init(x_array: Array=[], y_array: Array=[], z_array: Array=[]) -> void:
	x = x_array
	y = y_array
	z = z_array

func append(v: Variant) -> void:
	if not CustomVector3.is_valid(v):
		return
	x.append(v.x)
	y.append(v.y)
	z.append(v.z)

func _to_string() -> String:
	return "(" + str(x) + ", " + str(y) + ", " + str(z) + ")"
