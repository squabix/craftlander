extends Node3D
class_name TreeResource

const MIN_HP := 3
const MAX_HP := 5

@onready var state_machine: StateMachine = $StateMachine
@onready var hurtbox: Hurtbox3D = $Trunk/Hurtbox3D
@onready var trunk: Node3D = $Trunk
@onready var inventory: Inventory = $Inventory
@onready var chop_particles: GPUParticles3D = $ChopParticles
@onready var health: Health = $Health

func _ready() -> void:
	health.hp = float(randi_range(MIN_HP, MAX_HP))
	var connect_hurtbox := func() -> void:
		Util.find_child_of_class(self, "Hurtbox3D").was_dealt_damage.connect(give_wood)
	EventBus.subscribe(
		"island_populated",
		connect_hurtbox
	)

func give_wood(damage: Damage) -> void:
	inventory.give_item(
		inventory.get_item(0),
		1,
		Util.find_child_of_class(damage.source, "Inventory")
	)
