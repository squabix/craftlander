class_name RangeVector3
extends Resource

@export var bool_vector: BoolVector3
@export var x_min: float = 0.0
@export var x_max: float = 0.0
@export var y_min: float = 0.0
@export var y_max: float = 0.0
@export var z_min: float = 0.0
@export var z_max: float = 0.0


func _to_string() -> String:
	return "(" + str(x_min) + " to " + str(x_max) + ", " + str(y_min) + " to " + str(y_max) + ", " + str(z_min) + " to " + str(z_max) + ")"


func clamp_vector(vector: Vector3) -> Vector3:
	return Vector3(
		clampx(vector.x),
		clampy(vector.y),
		clampz(vector.z),
	)


func clampx(x: float) -> float:
	_default_bool_vector()
	if bool_vector.x:
		x = clampf(x, x_min, x_max)
	return x


func clampy(y: float) -> float:
	_default_bool_vector()
	if bool_vector.y:
		y = clampf(y, y_min, y_max)
	return y


func clampz(z: float) -> float:
	_default_bool_vector()
	if bool_vector.z:
		z = clampf(z, z_min, z_max)
	return z


func wrap_vector(vector: Vector3) -> Vector3:
	_default_bool_vector()
	if bool_vector.x:
		vector.x = wrapf(vector.x, x_min, x_max)
	if bool_vector.y:
		vector.y = wrapf(vector.y, y_min, y_max)
	if bool_vector.y:
		vector.y = wrapf(vector.y, z_min, z_max)
	return vector


func get_min() -> Vector3:
	return Vector3(x_min, y_min, z_min)


func get_max() -> Vector3:
	return Vector3(x_max, y_max, z_max)


func _default_bool_vector() -> void:
	if bool_vector == null:
		bool_vector = CustomVector3.new().default(true).classify()
