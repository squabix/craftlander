extends Node3D

signal opened

@export var unlock_item: Item

@export_group("Components")
@export var interactable: Interactable3D
@export var anim_player: AnimationPlayer

func _ready() -> void:
	interactable.interacted_with.connect(_on_interacted_with)
	

func _on_interacted_with(source: Node) -> void:
	if not source is Player:
		return
	
	var item_holder := Util.find_child_of_class(source, "ItemHolder3D") as ItemHolder3D
	if not is_instance_valid(item_holder):
		return
	
	var held_item := item_holder.get_held_item()
	if not unlock_item.equals(held_item):
		fail()
	else:
		open()

func fail() -> void:
	anim_player.play(&"locked")

func open() -> void:
	anim_player.play(&"open")
	interactable.disable()
	print("Opened treasure chest")
	EventBus.trigger("treasure_chest_opened")
	opened.emit()
