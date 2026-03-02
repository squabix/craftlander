extends Entity3D
class_name Player

const STANDING_HEAD_HEIGHT := 1.4
const CROUCHED_HEAD_HEIGHT := 0.7
const CROUCH_CAMERA_SPEED := 0.1

@onready var head: Node3D = $Head
@onready var movement_state_machine: StateMachine = $Controller3D/Free
@onready var inventory: Inventory = $Inventory
@onready var health: Health = $Health
@onready var hunger: Hunger = $Hunger
@onready var sickness_manager: SicknessManager = $SicknessManager
@onready var item_holder: ItemHolder3D = $Head/Camera3D/ArmContainer/ItemHolder
@onready var inventory_holder_link: InventoryHolderLink = $Head/Camera3D/ArmContainer/ItemHolder/InventoryHolderLink
@onready var dropper: InventoryDropper3D = $Head/Camera3D/DropperRayCast/InventoryDropper3D

func _ready() -> void:
	item_holder.item_event_triggered.connect(
		func(event: ItemEvent) -> void:
			if event is Food.AteFoodEvent:
				health.hp += event.health_restoration
				hunger.value += event.hunger_restoration
				sickness_manager.value += event.sickness
	)

func adjust_head_to_crouch() -> void:
	head.position.y = lerp(
		head.position.y,
		CROUCHED_HEAD_HEIGHT if movement_state_machine.is_currently("Crouching") else STANDING_HEAD_HEIGHT,
		CROUCH_CAMERA_SPEED
	)

func drop_current_item() -> void:
	dropper.drop(inventory_holder_link.current_index)

func _process(_delta: float) -> void:
	adjust_head_to_crouch()

func use_item() -> void:
	item_holder.use_item()

func interact() -> void:
	%Interactor.interact()
