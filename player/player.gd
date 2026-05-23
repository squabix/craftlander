extends Entity3D
class_name Player

const DEFAULT_HEAD_HEIGHT := 1.4
const CROUCHED_HEAD_HEIGHT := 0.7
const SWIMMING_HEAD_HEIGHT := 1.1
const HEAD_SPEED := 0.1

@export var head: Node3D
@export var movement_state_machine: StateMachine
@export var interactor: Interactor3D
@export var respawn_button: Button
@export var docking_hidden_interfaces: Array[Control] = []

@export_group("Inventory")
@export var inventory: Inventory
@export var item_holder: ItemHolder3D
@export var inventory_holder_link: InventoryHolderLink
@export var dropper: InventoryDropper3D

@export_group("Stats")
@export var health: Health
@export var hunger: Hunger
@export var stamina: Stamina

@export_group("External Dependencies")
@export var respawn_point_node: Node3D

var is_in_water := false

func _ready() -> void:
	item_holder.item_event_triggered.connect(
		func(event: ItemEvent) -> void:
			if event is Food.AteFoodEvent:
				health.hp += event.health_restoration
				hunger.value += event.hunger_restoration
	)
	respawn_button.pressed.connect(respawn)
	health.died.connect(die)

func get_target_head_height() -> float:
	if movement_state_machine.is_currently("Crouching"):
		return CROUCHED_HEAD_HEIGHT
	if is_in_water:
		return SWIMMING_HEAD_HEIGHT
	return DEFAULT_HEAD_HEIGHT

func adjust_head() -> void:
	head.position.y = lerp(
		head.position.y,
		get_target_head_height(),
		HEAD_SPEED
	)

func drop_current_item() -> void:
	dropper.drop(inventory_holder_link.current_index)

func _process(_delta: float) -> void:
	adjust_head()
	
	# Drown if swimming when out of stamina
	if is_in_water and not stamina.is_usable():
		health.hurt(INF)

func use_item() -> void:
	item_holder.use_item()

func interact() -> void:
	interactor.interact()

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
