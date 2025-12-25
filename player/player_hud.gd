extends Control

const ITEM_LABEL_FADE_LENGTH := 1.0

@onready var current_item_label: Label = $CurrentItemLabel
@onready var current_item_animation_player: AnimationPlayer = $CurrentItemLabel/AnimationPlayer

func _on_item_holder_updated_instance(new_instance: ItemInstance) -> void:
	current_item_label.text = new_instance.item.name
	current_item_animation_player.stop()
	current_item_animation_player.play("show")
