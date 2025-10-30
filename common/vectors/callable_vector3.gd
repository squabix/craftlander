extends Object
class_name CallableVector3

var x: Callable
var y: Callable
var z: Callable

func vector_call(vector: Variant = null) -> Variant:
	if not CustomVector3.is_valid(vector):
		return CustomVector3.new(
			x.call(),
			y.call(),
			z.call()
		).classify()
	return CustomVector3.new(
		x.call(vector.x),
		y.call(vector.y),
		z.call(vector.z)
	).classify()

func vector_callv(vector: ArrayVector3) -> Variant:
	return CustomVector3.new(
		x.callv(vector.x),
		y.callv(vector.y),
		z.callv(vector.z)
	).classify()

func _init(x_callable: Callable, y_callable: Callable, z_callable: Callable) -> void:
	x = x_callable
	y = y_callable
	z = z_callable

func _to_string() -> String:
	return "(" + str(x) + ", " + str(y) + ", " + str(z) + ")"
