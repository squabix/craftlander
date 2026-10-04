class_name IslandOption
extends CenterContainer

enum Status { AVAILABLE, CURRENT, LOCKED }

const LOCKED_NAME := "???"
const LOCKED_TINT := Color.BLACK
const CURRENT_STATUS_TEXT := "Current Location"
const LOCKED_STATUS_FORMAT := "Requires Boat Level %d"

@export var current_alpha := 0.7
@export var island_resource: IslandResource

@export_group("Components")
@export var name_label: Label
@export var texture_rect: TextureRect
@export var status_label: Label
@export var animation_player: AnimationPlayer

var status := Status.AVAILABLE


func _ready() -> void:
	if is_instance_valid(animation_player) and animation_player.has_animation(&"float"):
		animation_player.seek(randf() * animation_player.get_animation(&"float").length, true)


func reload(boat_level: int) -> void:
	status = get_status(boat_level)
	texture_rect.texture = island_resource.icon

	match status:
		Status.LOCKED:
			name_label.text = LOCKED_NAME
			status_label.text = LOCKED_STATUS_FORMAT % island_resource.index
			modulate.a = 1.0
		Status.CURRENT:
			name_label.text = island_resource.name
			status_label.text = CURRENT_STATUS_TEXT
			modulate.a = current_alpha
		Status.AVAILABLE:
			name_label.text = island_resource.name
			status_label.text = ""
			modulate.a = 1.0

	texture_rect.modulate = LOCKED_TINT if status == Status.LOCKED else Color.WHITE


func get_status(boat_level: int) -> Status:
	if island_resource.index > boat_level:
		return Status.LOCKED
	if island_resource.index == Main.current_level_index:
		return Status.CURRENT
	return Status.AVAILABLE


func is_sailable() -> bool:
	return status == Status.AVAILABLE
