extends Node3D

func _ready() -> void:
	await get_tree().process_frame
	EventBus.trigger("island_populated")

func _process(delta: float) -> void:
	pass
	#if Input.is_action_pressed("move_right"):
		#print("r")
		#$Tree.global_basis = Util.roll_basis_toward(
			#$Tree.global_basis,
			#Vector3.RIGHT,
			#Util.VECTOR3Y,
			#0.1
		#)
	#if Input.is_action_pressed("move_left"):
		#print("l")
		#$Tree.global_basis = Util.roll_basis_toward(
			#$Tree.global_basis,
			#Vector3(1, 1, -1),
			#Util.VECTOR3Y,
			#-0.1
		#)
