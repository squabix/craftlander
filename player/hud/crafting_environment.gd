extends SubViewportContainer
class_name CraftingEnvironment

const CAMERA_OFFSET := 0.0
const MAX_DRAG_DISTANCE := 1.0
const DRAG_SPEED := 0.1
const SNAP_SPEED := 1.0
const SPACE_POSITION := -Vector3.ONE * 1000.0

@onready var subviewport: SubViewport = $SubViewport
@onready var space: Node3D = $SubViewport/Space
@onready var item_origin: Node3D = $SubViewport/Space/ItemOrigin
@onready var camera: Camera3D = $SubViewport/Space/Camera3D

var dragged_item: Node3D
var is_crafting := false

func _ready() -> void:
	space.global_position = SPACE_POSITION

func get_scaled_mouse_position2d() -> Vector2:
	var local_mouse := get_local_mouse_position()
	return Vector2(
		local_mouse.x / size.x * subviewport.size.x,
		local_mouse.y / size.y * subviewport.size.y
	)

func get_mouse_position3d() -> Vector3:
	return Util.get_mouse_position_3d(
		camera,
		get_scaled_mouse_position2d()
	).move_toward(
		camera.global_position,
		CAMERA_OFFSET
	)

func spawn_item(item: Item) -> void:
	var pickup := ItemPickup3D.new()
	pickup.item = item
	item_origin.add_child(pickup)
	pickup.global_position = get_mouse_position3d()

func _process(delta: float) -> void:
	if not is_crafting:
		return
	
	$SubViewport/Space/MeshInstance3D.global_position = get_mouse_position3d()
	
	if Input.is_action_just_pressed("use_secondary"):
		var mouse := get_mouse_position3d()
		dragged_item = Util.distance_sort_3d(item_origin.get_children(), mouse)[0]
		if dragged_item.global_position.distance_to(mouse) > MAX_DRAG_DISTANCE:
			dragged_item = null
		
	if Input.is_action_just_released("use_secondary") and is_instance_valid(dragged_item):
		dragged_item.global_position = dragged_item.global_position.lerp(get_mouse_position3d(), SNAP_SPEED)
		dragged_item = null
	
	if is_instance_valid(dragged_item):
		dragged_item.global_position = dragged_item.global_position.lerp(get_mouse_position3d(), DRAG_SPEED)

func _input(event: InputEvent) -> void:
	if not is_crafting:
		return
	if event.is_action_pressed("use_primary"):
		spawn_item(load("res://items/wood/wood_item.tres"))
