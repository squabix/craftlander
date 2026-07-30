class_name RigidItemPickup3D
extends RigidBody3D

@export var item_pickup_interactable: ItemPickup3D
@export var hurtbox: Hurtbox3D
@export var saved_item: Item:
	get:
		return item_pickup_interactable.item if has_interactable() else saved_item
	set(value):
		if not has_interactable():
			return
		item_pickup_interactable.item = value
		item_pickup_interactable.update_visuals()


static func from_item(item: Item, scene: PackedScene) -> RigidItemPickup3D:
	if item == null:
		return
	var scene_instance := scene.instantiate() as RigidItemPickup3D
	if scene_instance == null:
		return
	scene_instance.saved_item = item
	return scene_instance


func _ready() -> void:
	freeze = true
	if not is_instance_valid(item_pickup_interactable):
		return

	item_pickup_interactable.auto_generate_collision = false
	item_pickup_interactable.picked_up.connect(Util.safe_free.bind(self))

	item_pickup_interactable.generate_all_collision(item_pickup_interactable)
	item_pickup_interactable.update_tooltip()

	var collision_shapes := item_pickup_interactable.generate_all_collision(self)
	
	# Duplicate collision shapes to hurtbox
	if hurtbox:
		for collision_shape in collision_shapes:
			var hurtbox_collision_duplicate: CollisionShape3D = collision_shape.duplicate()
			hurtbox.add_child(hurtbox_collision_duplicate)
			hurtbox_collision_duplicate.global_transform = collision_shape.global_transform

	await get_tree().physics_frame
	freeze = false


func has_interactable() -> bool:
	return is_instance_valid(item_pickup_interactable)
