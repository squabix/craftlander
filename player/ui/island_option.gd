class_name IslandOption
extends VBoxContainer

signal selected

@export var current_alpha := 1.0
@export var island_resource: IslandResource

@export_group("Components")
@export var name_label: Label
@export var texture_rect: TextureRect
@export var select_button: Button
@export var animation_player: AnimationPlayer

func _ready() -> void:
	select_button.pressed.connect(selected.emit)
	if is_instance_valid(animation_player) and animation_player.has_animation(&"float"):
		animation_player.seek(randf() * animation_player.get_animation(&"float").length, true)
	await get_tree().process_frame
	name_label.text = island_resource.name

func reload() -> void:
	show()
	texture_rect.texture = island_resource.icon
	modulate.a = current_alpha if Main.current_level_index == island_resource.index else 1.0
	select_button.disabled =  Main.current_level_index == island_resource.index
