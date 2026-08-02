class_name ItemCooldownRadial
extends ProgressRadial

@export var item_holder: ItemHolder3D

func _process(_delta: float) -> void:
	update_value()

func update_value() -> void:
	if item_holder.held_item_instance == null or item_holder.held_item_instance.item.cooldown_length <= 0.0:
		value = 1.0
		return
	value = item_holder.held_item_instance.item.get_cooldown_completion()
