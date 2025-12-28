extends Entity3D
class_name Player

const STANDING_HEAD_HEIGHT := 1.4
const CROUCHED_HEAD_HEIGHT := 0.7
const CROUCH_CAMERA_SPEED := 0.1

@onready var head: Node3D = $Head
@onready var state_machine: StateMachine = $StateMachine
@onready var inventory: Inventory = $Inventory
@onready var inventory_holder_link: InventoryHolderLink = $Head/Camera3D/ArmContainer/ItemHolder/InventoryHolderLink
@onready var dropper: InventoryDropper3D = $Head/Camera3D/DropperRayCast/InventoryDropper3D

func adjust_head_to_crouch() -> void:
	head.position.y = lerp(
		head.position.y,
		CROUCHED_HEAD_HEIGHT if state_machine.is_currently("Crouching") else STANDING_HEAD_HEIGHT,
		CROUCH_CAMERA_SPEED
	)

func drop_current_item() -> void:
	dropper.drop(inventory_holder_link.current_index)

func _process(_delta: float) -> void:
	adjust_head_to_crouch()

func use_item() -> void:
	$Head/Camera3D/ArmContainer/ItemHolder.use_item()

func interact() -> void:
	%Interactor.interact()
