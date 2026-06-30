class_name BoolVector2
extends Resource

@export var x: bool = true
@export var y: bool = true


static func construct(x: bool, y: bool) -> BoolVector2:
	var bv: BoolVector2 = BoolVector2.new()
	bv.x = x
	bv.y = y
	return bv


static func from_vector(vector: Vector2) -> BoolVector2:
	return construct(
		vector.x != 0.0,
		vector.y != 0.0,
	)


static func cut(vector: Vector2, with: BoolVector2, normalize: bool = false, default: Vector2 = Vector2.ONE) -> Vector2:
	var unnormalized_result: Vector2 = vector

	if with != null:
		unnormalized_result *= with.get_vector()
	else:
		unnormalized_result *= default

	if normalize:
		return unnormalized_result.normalized()
	return unnormalized_result


static func replace(v: Vector2, with: Vector2, bv: BoolVector2) -> Vector2:
	if bv == null:
		return with

	if bv.x:
		v.x = with.x
	if bv.y:
		v.y = with.y
	return v


func _to_string() -> String:
	return "(" + str(x) + ", " + str(y) + ")"


func interpolate(from: Vector2, to: Vector2, weight: float, default: Vector2 = Vector2.ZERO) -> Vector2:
	var result: Vector2 = default
	if x:
		result.x = lerp(from.x, to.x, weight)
	if y:
		result.y = lerp(from.y, to.y, weight)
	return result


func interpolate_angle(from: Vector2, to: Vector2, weight: float, default: Vector2 = Vector2.ZERO) -> Vector2:
	var result: Vector2 = default
	if x:
		result.x = lerp_angle(from.x, to.x, weight)
	if y:
		result.y = lerp_angle(from.y, to.y, weight)
	return result


func get_vector() -> Vector2:
	return Vector2(
		1.0 if x else 0.0,
		1.0 if y else 0.0,
	)


func get_inverted() -> BoolVector2:
	var inverted: BoolVector2 = self.duplicate()
	inverted.x = !inverted.x
	inverted.y = !inverted.y
	return inverted
