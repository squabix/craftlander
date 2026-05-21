extends CharacterBody3D
class_name Entity3D

signal landed
signal left_ground

@export var type := "default_entity"
@export var movement_mode: MovementMode3D
@export var move_up_as_jump := true

@export_group("Gravity")
@export var does_obey_gravity := true
@export var gravity_multiplier := 1.0

@export_group("Rigid Bodies")
@export var do_push_rigid_bodies := false
@export var rigid_body_push_force := 4.0

@export_group("Rotation")
@export var accelerate_rotation_base: Node3D = self
@export var horizontal_rotation_target: Node3D
@export var vertical_rotation_target: Node3D
@export var rotation_range: RangeVector3
@export var default_rotation_targets_to_entity := true

var was_on_floor := false
var frozen := false

var motion_direction := Vector3.ZERO
var last_motion_direction := Vector3.ZERO
var queued_impulse := Vector3.ZERO

func _ready() -> void:
	# Fallback initialization to prevent runtime Null Pointer crashes
	if default_rotation_targets_to_entity:
		if not is_instance_valid(horizontal_rotation_target):
			horizontal_rotation_target = self
		if not is_instance_valid(vertical_rotation_target):
			vertical_rotation_target = self

func get_total_rotation_degrees() -> Vector3:
	var v = vertical_rotation_target.rotation_degrees.x if is_instance_valid(vertical_rotation_target) else 0.0
	var h = horizontal_rotation_target.rotation_degrees.y if is_instance_valid(horizontal_rotation_target) else 0.0
	return Vector3(v, h, rotation_degrees.z)

func get_rotated_velocity() -> Vector3:
	return velocity.rotated(Vector3.UP, -global_rotation.y)

func get_planar_velocity_length() -> float:
	return Util.vec3to2(velocity, Util.VECTOR3Y).length()

func rotate_horizontal(deg: float) -> void:
	if is_instance_valid(horizontal_rotation_target):
		horizontal_rotation_target.rotation_degrees.y += deg

func rotate_vertical(deg: float) -> void:
	if is_instance_valid(vertical_rotation_target):
		vertical_rotation_target.rotation_degrees.x += deg

func add_impulse(impulse: Vector3) -> void:
	queued_impulse += impulse

func face_target(target: Variant) -> void:
	var target_position := Vector3.ZERO
	if target is Vector3:
		target_position = target
	elif target is Node3D and is_instance_valid(target):
		target_position = target.global_position
	else:
		return
	
	if target_position.is_equal_approx(global_position):
		return
		
	# Prevent crashing if target is perfectly vertical above/below entity
	if not is_equal_approx(target_position.x, global_position.x) or not is_equal_approx(target_position.z, global_position.z):
		look_at(target_position, Vector3.UP)

func face_velocity() -> void:
	if velocity.is_zero_approx() or is_equal_approx(abs(velocity.normalized().y), 1.0):
		return
	look_at(global_position + velocity, Vector3.UP)

func move_planar(direction: Vector2) -> void:
	motion_direction.x = direction.x
	motion_direction.z = direction.y # Map Y vector input to 3D Depth space Z

func move_forward(amount: float = 1.0) -> void: motion_direction.z = -amount
func move_backward(amount: float = 1.0) -> void: motion_direction.z = amount
func move_left(amount: float = 1.0) -> void: motion_direction.x = -amount
func move_right(amount: float = 1.0) -> void: motion_direction.x = amount
func move_up(amount: float = 1.0) -> void: motion_direction.y = amount
func move_down(amount: float = 1.0) -> void: motion_direction.y = -amount

func _accelerate(direction: Vector3) -> void:
	if movement_mode == null:
		return
	
	if frozen:
		direction = Vector3.ZERO
	elif accelerate_rotation_base != null:
		direction = direction.rotated(Vector3.UP, accelerate_rotation_base.global_rotation.y)
	
	velocity = movement_mode.accel(velocity, direction) 
	if not queued_impulse.is_zero_approx():
		velocity += queued_impulse
		queued_impulse = Vector3.ZERO

func jump() -> void:
	if is_on_floor():
		move_up()

func rotate_targets() -> void:
	if rotation_range == null:
		return
		
	if is_instance_valid(vertical_rotation_target):
		vertical_rotation_target.rotation_degrees.x = rotation_range.clampx(vertical_rotation_target.rotation_degrees.x)
	
	if is_instance_valid(horizontal_rotation_target):
		horizontal_rotation_target.rotation_degrees.y = rotation_range.clampy(horizontal_rotation_target.rotation_degrees.y)
		horizontal_rotation_target.rotation_degrees.z = rotation_range.clampz(horizontal_rotation_target.rotation_degrees.z)

func _physics_process(delta: float) -> void:
	if not is_on_floor() and does_obey_gravity:
		velocity += GameWorld.get_current().get_gravity3d(gravity_multiplier)
	
	_accelerate(motion_direction)
	
	last_motion_direction = motion_direction
	motion_direction = Vector3.ZERO
	
	move_and_slide()
	rotate_targets()
	
	# Signal checking system updates correctly now
	if was_on_floor and not is_on_floor():
		left_ground.emit()
	elif not was_on_floor and is_on_floor():
		landed.emit()
		
	was_on_floor = is_on_floor()
	
	if do_push_rigid_bodies:
		push_rigid_bodies()

func push_rigid_bodies() -> void:
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var body = c.get_collider()
		if body is RigidBody3D:
			# Apply impulse scaled by force at the point of impact
			body.apply_central_impulse(-c.get_normal() * rigid_body_push_force)

func _to_string() -> String:
	return "%s (%s)" % [name, type]

func print_movement() -> void:
	print("%s velocity: %s via %s\n" % [self, velocity, movement_mode])
