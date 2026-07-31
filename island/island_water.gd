extends Area3D

const SINK_DEPTH := 5.0

@export var sink_duration: float = 4.0


func _ready() -> void:
	body_entered.connect(_on_body_entered_water)
	body_exited.connect(_on_body_exited_water)


func sink(body: RigidBody3D) -> void:
	body.freeze = true

	NodeSaver.offload_node(body)

	# Create a tween targeting the object's global Y position
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(body, "global_position:y", global_position.y - SINK_DEPTH, sink_duration)

	await tween.finished
	Util.safe_free(body)


func _on_body_entered_water(body: PhysicsBody3D) -> void:
	if body is Player:
		body.is_in_water = true
	elif body is RigidItemPickup3D and body.is_set_up:
		sink(body)


func _on_body_exited_water(body: PhysicsBody3D) -> void:
	if body is Player:
		body.is_in_water = false
