class_name IslandOption
extends VBoxContainer

signal selected

@export var current_alpha := 1.0

@export_group("Island Information", "island")
@export var island_name := "Island"
@export var island_index := 0

@export_group("Components")
@export var name_label: Label
@export var texture_rect: TextureRect
@export var select_button: Button

func _ready() -> void:
	select_button.pressed.connect(selected.emit)
	await get_tree().process_frame
	name_label.text = island_name

func reload() -> void:
	show()
	modulate.a = current_alpha if Main.current_level_index == island_index else 1.0
	select_button.disabled =  Main.current_level_index == island_index
