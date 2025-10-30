extends Resource
class_name BoolVector3

@export var x: bool = true
@export var y: bool = true
@export var z: bool = true

static func construct(x: bool, y: bool, z: bool) -> BoolVector3:
	var bv: BoolVector3 = BoolVector3.new()
	bv.x = x
	bv.y = y
	bv.z = z
	return bv

static func from_vector(v: Vector3) -> BoolVector3:
	return construct(
		v.x != 0.0,
		v.y != 0.0,
		v.z != 0.0,
	)

static func cut(v: Vector3, bv: BoolVector3, normalize: bool = false, default: Vector3 = Vector3.ONE) -> Vector3:
	var unnormalized_result: Vector3 = v
	
	if bv != null:
		unnormalized_result *= bv.get_vector()
	else:
		unnormalized_result *= default
	
	if normalize:
		return unnormalized_result.normalized()
	return unnormalized_result

static func replace(v: Vector3, with: Vector3, bv: BoolVector3) -> Vector3:
	if bv == null:
		return with
	
	if bv.x:
		v.x = with.x
	if bv.y:
		v.y = with.y
	if bv.z:
		v.z = with.z
	return v

func interpolate(from: Vector3, to: Vector3, weight: float, default: Vector3=Vector3.ZERO) -> Vector3:
	var result: Vector3 = default
	if x:
		result.x = lerp(from.x, to.x, weight)
	if y:
		result.y = lerp(from.y, to.y, weight)
	if z:
		result.z = lerp(from.z, to.z, weight)
	return result

func interpolate_angle(from: Vector3, to: Vector3, weight: float, default: Vector3=Vector3.ZERO) -> Vector3:
	var result: Vector3 = default
	if x:
		result.x = lerp_angle(from.x, to.x, weight)
	if y:
		result.y = lerp_angle(from.y, to.y, weight)
	if z:
		result.z = lerp_angle(from.z, to.z, weight)
	return result

func get_vector() -> Vector3:
	return Vector3(
		1.0 if x else 0.0,
		1.0 if y else 0.0,
		1.0 if z else 0.0
	)

func get_inverted() -> BoolVector3:
	var inverted: BoolVector3 = self.duplicate()
	inverted.x = !inverted.x
	inverted.y = !inverted.y
	inverted.z = !inverted.z
	return inverted

func _to_string() -> String:
	return "(" + str(x) + ", " + str(y) + ", " + str(z) + ")"
