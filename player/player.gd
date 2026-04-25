extends Entity3D
class_name Player

const DEFAULT_HEAD_HEIGHT := 1.4
const CROUCHED_HEAD_HEIGHT := 0.7
const SWIMMING_HEAD_HEIGHT := 1.1
const CROUCH_CAMERA_SPEED := 0.1

@onready var head: Node3D = $Head
@onready var movement_state_machine: StateMachine = $Controller3D/Default
@onready var inventory: Inventory = $Inventory
@onready var health: Health = $Health
@onready var hunger: Hunger = $Hunger
@onready var item_holder: ItemHolder3D = $Head/Camera3D/ArmContainer/ItemHolder
@onready var inventory_holder_link: InventoryHolderLink = $Head/Camera3D/ArmContainer/ItemHolder/InventoryHolderLink
@onready var dropper: InventoryDropper3D = $Head/Camera3D/DropperRayCast/InventoryDropper3D
@onready var respawn_button: Button = $HUD/DeathScreen/OptionsContainer/RespawnButton

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

func adjust_head() -> void:
	var height: float = DEFAULT_HEAD_HEIGHT
	if movement_state_machine.is_currently("Crouching"):
		height = CROUCHED_HEAD_HEIGHT
	elif is_in_water:
		height = SWIMMING_HEAD_HEIGHT
	
	head.position.y = lerp(
		head.position.y,
		height,
		CROUCH_CAMERA_SPEED
	)

func drop_current_item() -> void:
	dropper.drop(inventory_holder_link.current_index)

func _process(_delta: float) -> void:
	adjust_head()
	if is_in_water and not %Stamina.is_usable():
		health.hurt(INF)

func use_item() -> void:
	item_holder.use_item()

func interact() -> void:
	%Interactor.interact()

func die() -> void:
	get_tree().paused = true
	MouseModeController.show()

func respawn() -> void:
	
	# Transform to respawn point
	global_position = respawn_point_node.global_position
	global_rotation = respawn_point_node.global_rotation
	
	# Replenish stats
	$Health.revive()
	hunger.value = hunger.initial_value
	%Stamina.value = 1.0
	
	MouseModeController.capture()
	get_tree().paused = false
