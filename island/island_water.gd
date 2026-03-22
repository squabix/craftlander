extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered_water)
	body_exited.connect(_on_body_exited_water)

func _on_body_entered_water(body: PhysicsBody3D) -> void:
	if body is Player:
		body.is_in_water = true

func _on_body_exited_water(body: PhysicsBody3D) -> void:
	if body is Player:
		body.is_in_water = false
