extends Node3D
class_name DestructableResource

@export var min_hp: int = 3
@export var max_hp: int = 5

@export var hurtbox: Hurtbox3D
@export var inventory: Inventory
@export var health: Health

func _ready() -> void:
	if health != null:
		health.hp = float(randi_range(min_hp, max_hp))
	
	# Once island is populated, connect hurtbox damage signal to give first inventory item to damager
	if hurtbox != null and inventory != null:
		EventBus.subscribe(
			"island_populated",
			func() -> void:
				Util.find_child_of_class(self, "Hurtbox3D").was_dealt_damage.connect(
					func(damage: Damage) -> void:
						inventory.give_item(
							inventory.get_item(inventory.get_random_index_weighted()),
							1,
							Util.find_child_of_class(damage.source, "Inventory")
						)
				),
			tree_exiting
		)
