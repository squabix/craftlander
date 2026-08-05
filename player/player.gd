class_name Player
extends Entity3D

const DEFAULT_HEAD_HEIGHT := 1.4
const CROUCHED_HEAD_HEIGHT := 0.7
const SWIMMING_HEAD_HEIGHT := 0.85
const HEAD_SPEED := 0.1

@export_group("Components")
@export var movement_state_machine: StateMachine

@export_subgroup("3D")
@export var head: Node3D
@export var interactors: Array[Interactor3D]

@export_subgroup("Control")
@export var respawn_button: Button
@export var boat_interface: BoatInterface
@export var docking_hidden_interfaces: Array[Control] = []

@export_group("Inventory")
@export var item_holder: InventoryHolder3D
@export var dropper: InventoryDropper3D

@export_group("Stats")
@export var health: Health
@export var health_saver: NodeSaver
@export var hunger: Hunger
@export var hunger_saver: NodeSaver
@export var stamina: Stamina

@export_group("Audio")
@export var steps_player: CharacterAudioStreamPlayer3D
@export var swim_player: CharacterAudioStreamPlayer3D
@export var eat_player: AudioStreamPlayer

@export_group("External Dependencies")
@export var respawn_point_node: Node3D

var is_in_water := false


func _ready() -> void:
	item_holder.item_event_triggered.connect(
		func(event: ItemEvent) -> void:
			if event is Food.AteFoodEvent:
				health.hp += event.health_restoration
				hunger.value += event.hunger_restoration
				eat_player.play()
	)
	respawn_button.pressed.connect(respawn)
	health.died.connect(die)
	health_saver.finished_load.connect(_on_health_loaded, CONNECT_ONE_SHOT)
	hunger_saver.finished_load.connect(_on_hunger_loaded, CONNECT_ONE_SHOT)


func _on_health_loaded() -> void:
	if health.hp <= 0.0:
		health.hp = health.max_hp


func _on_hunger_loaded() -> void:
	if hunger.value <= 0.0:
		hunger.value = hunger.initial_value


func _process(_delta: float) -> void:
	adjust_head()

	# Drown if swimming when out of stamina
	if is_in_water and not stamina.is_usable():
		health.hurt(INF)


func set_character_stream_player(to: CharacterAudioStreamPlayer3D) -> void:
	steps_player.disabled = steps_player != to
	swim_player.disabled = swim_player != to


func get_target_head_height() -> float:
	if movement_state_machine.is_currently(&"Crouching"):
		return CROUCHED_HEAD_HEIGHT
	if is_in_water:
		return SWIMMING_HEAD_HEIGHT
	return DEFAULT_HEAD_HEIGHT


func adjust_head() -> void:
	head.position.y = lerp(
		head.position.y,
		get_target_head_height(),
		HEAD_SPEED,
	)


func drop_selected_item() -> void:
	dropper.drop(item_holder.selector.selected_index)


func use_item() -> void:
	item_holder.use_item()


func interact() -> void:
	for interactor in interactors:
		if interactor.interact() != null:
			return


func die() -> void:
	get_tree().paused = true
	MouseModeController.show()


func respawn() -> void:
	# Transform to respawn point
	global_position = respawn_point_node.global_position
	global_rotation = respawn_point_node.global_rotation

	# Replenish stats
	health.revive()
	hunger.value = hunger.initial_value
	stamina.value = 1.0

	MouseModeController.capture()
	get_tree().paused = false


func _on_pause_interface_updated_pause(to: bool) -> void:
	if to == true:
		return
	await get_tree().process_frame
	item_holder.selector.update_current_instance()
