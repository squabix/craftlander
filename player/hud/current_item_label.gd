extends Label

@export var anim_player: AnimationPlayer 
@export var item_holder: ItemHolder3D

func _ready() -> void:
	item_holder.updated_instance.connect(update)

func update(new_instance: ItemInstance) -> void:
	text = new_instance.item.name
	anim_player.stop()
	anim_player.play("show")
