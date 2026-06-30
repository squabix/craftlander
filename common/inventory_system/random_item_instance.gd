class_name RandomItemInstance
extends ItemInstance

@export var min_quantity := 0
@export var max_quantity := 1
@export var quantity_curve: Curve


func _init() -> void:
	randomize_quantity.call_deferred()


func randomize_quantity() -> void:
	if quantity_curve == null:
		quantity_curve = CurveUtil.linear_curve()
	quantity = min_quantity + int(quantity_curve.sample(randf()) * (max_quantity - min_quantity))
