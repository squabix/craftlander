extends Node3D
class_name TreeResource

@onready var state_machine: StateMachine = $StateMachine
@onready var hurtbox: Hurtbox3D = $FallingPivot/Hurtbox3D
@onready var falling_pivot: Node3D = $FallingPivot



func _on_health_died() -> void:
	falling_pivot.look_at(hurtbox.last_hurt_from)
	#falling_pivot.rotation_degrees.x = lerp(falling_pivot.rotatio)
