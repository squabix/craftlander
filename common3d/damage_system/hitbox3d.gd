extends Area3D
class_name Hitbox3D

signal hit_node

enum Mode {ENTERING, INSIDE, EXTERNAL}

@export var damage: Damage
@export var current_mode: Mode
@export var one_shot: bool
@export var enabled: bool = true
@export var auto_enable_wait_time: float

var hit_nodes: Array[Node]

func enable() -> void:
	enabled = true

func disable() -> void:
	enabled = false

func _ready() -> void:
	if damage == null:
		printerr(name, " has no damage")
	
	area_entered.connect(_hit_enter)
	if auto_enable_wait_time > 0.0:
		enabled = false
		await get_tree().create_timer(auto_enable_wait_time).timeout
		enabled = true

func _process(_delta: float) -> void:
	if current_mode == Mode.INSIDE:
		hit_overlap()

func hit_overlap() -> Array[Area3D]:
	var overlap: Array[Area3D] = get_overlapping_areas()
	for area in overlap:
		hit(area)
	return overlap

func _hit_enter(area: Area3D) -> bool:
	if current_mode == Mode.ENTERING:
		return hit(area)
	return false

func hit(area: Area3D) -> bool:
	
	# BAIL if not enabled
	if not enabled:
		return false
	
	# ERROR if area does not exist
	if not is_instance_valid(area):
		printerr(name, " cannot hit ", area, " because it is invalid")
		return false
	
	# BAIL if area has already been hit & can only be hit once
	if area in hit_nodes and one_shot:
		return false
	
	# BAIL if area is not a hurtbox
	if not (area is Hurtbox3D):
		return false
	
	area.hurt(damage.sample())
	hit_nodes.append(area)
	hit_node.emit()
	
	return true
