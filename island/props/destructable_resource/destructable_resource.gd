extends Node3D
class_name DestructableResource

@export var min_hp: int = 3
@export var max_hp: int = 5

@export var hurtbox: Hurtbox3D
@export var inventory: Inventory
@export var health: Health

var damage_source_inventories: Dictionary[Node, Inventory] = {}

func randomize_health() -> void:
	if not is_instance_valid(health):
		return
	health.hp = float(randi_range(min_hp, max_hp))

func connect_hurtbox_damage() -> void:
	var give_to_source := func(damage: Damage):
		give_random_item(get_damage_source_inventory(damage.source))
	hurtbox.was_dealt_damage.connect(give_to_source)

func get_damage_source_inventory(source: Node) -> Inventory:
	return Util.find_stored_child_of_class(damage_source_inventories, source)

func give_random_item(to: Inventory) -> void:
	var item := inventory.get_item(inventory.get_random_index_weighted())
	inventory.give_item(item, 1, to)

func _ready() -> void:
	randomize_health()
	
	if not Util.are_instances_valid([inventory, hurtbox]):
		return
	
	# Once island is populated, connect hurtbox damage signal to give first inventory item to damager
	EventBus.subscribe(
		"island_populated",
		connect_hurtbox_damage,
		tree_exiting
	)
