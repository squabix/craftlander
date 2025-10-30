extends Entity3D
class_name Player

const STANDING_HEAD_HEIGHT: float = 1.4
const CROUCHED_HEAD_HEIGHT: float = 0.7
const CROUCH_CAMERA_SPEED: float = 0.1

@onready var head: Node3D = $Head
@onready var state_machine: StateMachine = $StateMachine

@onready var inventory_holder_link: InventoryHolderLink = $Head/Camera3D/ArmContainer/ItemHolder/InventoryHolderLink

func adjust_camera_to_crouch() -> void:
	head.position.y = lerp(
		head.position.y,
		CROUCHED_HEAD_HEIGHT if state_machine.current == %CrouchedState else STANDING_HEAD_HEIGHT,
		CROUCH_CAMERA_SPEED
	)

func _process(_delta: float) -> void:
	if Input.is_action_pressed("use_right"):
		$Head/Camera3D/ArmContainer/ItemHolder.use_item()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		%Interactor.interact()
	elif event.is_action_pressed("scroll_up"):
		inventory_holder_link.scroll(-1)
	elif event.is_action_pressed("scroll_down"):
		inventory_holder_link.scroll(1)
