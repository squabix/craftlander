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

var was_on_floor: bool
var frozen: bool

var gravity: Vector3
var motion_direction: Vector3
var last_motion_direction: Vector3

var queued_impulse: Vector3

func get_total_rotation_degrees() -> Vector3:
	return Vector3(
		vertical_rotation_target.rotation_degrees.x,
		horizontal_rotation_target.rotation_degrees.y,
		rotation_degrees.z
	)

func get_rotated_velocity() -> Vector3:
	return velocity.rotated(Vector3.UP, -global_rotation.y)

func get_planar_velocity_length() -> float:
	return Util.vec3to2(velocity, Util.VECTOR3Y).length()

func rotate_horizontal(deg: float) -> void:
	horizontal_rotation_target.rotation_degrees.y += deg

func rotate_vertical(deg: float) -> void:
	vertical_rotation_target.rotation_degrees.x += deg

func add_impulse(impulse: Vector3) -> void:
	queued_impulse += impulse

func face_target(target: Variant) -> void:
	var identified_target := false
	var target_position := Vector3.ZERO
	
	if target is Vector3:
		target_position = target
		identified_target = true
	
	elif target is Node3D:
		if not is_instance_valid(target):
			return
		target_position = target.global_position
		identified_target = true
	
	if identified_target == false:
		return
	
	if target_position.x == global_position.x and target_position.z == global_position.z:
		return
	
	look_at(target_position)

func face_velocity() -> void:
	if velocity.x == 0.0 and velocity.z == 0.0:
		return
	if velocity == Vector3.ZERO:
		return
	look_at(global_position + velocity)

func move_planar(direction: Vector2) -> void:
	if direction.x > 0.0:
		move_right(direction.x)
	elif direction.x < 0.0:
		move_left(abs(direction.x))
	if direction.y > 0.0:
		move_forward(direction.y)
	elif direction.y < 0.0:
		move_backward(abs(direction.y))

func move_forward(amount: float=1.0) -> void:
	motion_direction.z = -amount

func move_backward(amount: float=1.0) -> void:
	motion_direction.z = amount

func move_left(amount: float=1.0) -> void:
	motion_direction.x = -amount

func move_right(amount: float=1.0) -> void:
	motion_direction.x = amount

func move_up(amount: float=1.0) -> void:
	motion_direction.y = amount

func move_down(amount: float=1.0) -> void:
	motion_direction.y = -amount

func _accelerate(direction: Vector3) -> void:
	if movement_mode == null:
		return
	
	if frozen:
		direction = Vector3.ZERO
	
	# Rotate direction based on target
	elif accelerate_rotation_base != null:
		direction = direction.rotated(
			Vector3.UP,
			accelerate_rotation_base.global_rotation.y
		)
	
	velocity = movement_mode.accel(velocity, direction) 
	velocity += queued_impulse
	queued_impulse = Vector3.ZERO

func reset_gravity() -> void:
	gravity = Vector3.ZERO

func jump() -> void:
	if not is_on_floor():
		return
	move_up()

func rotate_targets() -> void:
	if rotation_range == null:
		return
	if is_instance_valid(vertical_rotation_target):
		vertical_rotation_target.rotation_degrees.x = rotation_range.clampx(
			vertical_rotation_target.rotation_degrees.x
		)
	elif default_rotation_targets_to_entity:
		vertical_rotation_target = self
	
	if is_instance_valid(horizontal_rotation_target):
		horizontal_rotation_target.rotation_degrees.y = rotation_range.clampy(
			horizontal_rotation_target.rotation_degrees.y
		)
		horizontal_rotation_target.rotation_degrees.z = rotation_range.clampz(
			horizontal_rotation_target.rotation_degrees.z
		)
	elif default_rotation_targets_to_entity:
		horizontal_rotation_target = self

func _physics_process(delta: float) -> void:
	
	# Fall or reset gravity
	if not is_on_floor():
		gravity += GameWorld.get_current().get_gravity3d(gravity_multiplier)
	else:
		reset_gravity()
	
	# Add forces to velocity
	if not is_on_floor() and does_obey_gravity:
		velocity += gravity
	
	_accelerate(motion_direction)
	last_motion_direction = motion_direction
	motion_direction = Vector3.ZERO
	move_and_slide()
	
	rotate_targets()
	
	# Emit collision signals
	if was_on_floor and not is_on_floor():
		left_ground.emit()
	elif not was_on_floor and is_on_floor():
		landed.emit()
	
	push_rigid_bodies()

func push_rigid_bodies() -> void:
	if not do_push_rigid_bodies:
		return
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			c.get_collider().apply_central_impulse(-c.get_normal() * rigid_body_push_force)

func _to_string() -> String:
	return name + " (" + type + ")"

func print_movement() -> void:
	print(self, " velocity: ", velocity, " via ", movement_mode, "\n")
