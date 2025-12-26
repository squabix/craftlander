extends Interactable3D

const WOOD_COST := 10

var crafting_bench_scene := preload("res://utilities/crafting_bench/crafting_bench.tscn")

func interact(source: Node, _etc: Dictionary={}) -> void:
	var inventory: Inventory = Util.find_child_of_class(source, "Inventory")
	var wood_imitation := Item.imitate("Wood")
	if inventory.get_item_quantity(wood_imitation) < WOOD_COST:
		print("Not enough!")
		return
	inventory.remove_item(wood_imitation, WOOD_COST)
	Util.safe_free(get_parent())
	var bench: Node3D = crafting_bench_scene.instantiate()
	get_tree().root.add_child(bench)
	bench.global_transform = get_parent_node_3d().global_transform
	$ParticleSpawner3D.spawn()
