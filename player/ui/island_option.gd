class_name IslandOption
extends VBoxContainer

signal selected

@export_group("Island Information", "island")
@export var island_name := &"Island"
@export var island_index := 0

@export_group("Children")
@export var name_label: Label
@export var texture_rect: TextureRect
@export var select_button: Button

func _ready() -> void:
	select_button.pressed.connect(selected.emit)
	name_label.text = str(island_name)

func reload() -> void:
	show()
