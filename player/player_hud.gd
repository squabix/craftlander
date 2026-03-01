extends Control

const ITEM_LABEL_FADE_LENGTH := 1.0

@onready var current_item_label: Label = $InventoryInterface/CurrentItemLabel
@onready var current_item_anim_player: AnimationPlayer = $InventoryInterface/CurrentItemLabel/AnimationPlayer

@onready var boat_hidden_interface: Array[Control] = [
	$BarContainer,
	$InventoryInterface,
	$Cursor
]

func _on_item_holder_updated_instance(new_instance: ItemInstance) -> void:
	current_item_label.text = new_instance.item.name
	current_item_anim_player.stop()
	current_item_anim_player.play("show")

func _on_controller_3d_updated_entity(to: Entity3D) -> void:
	for control in boat_hidden_interface:
		control.visible = to.type != "boat"
