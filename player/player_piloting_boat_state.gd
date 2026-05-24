extends State

func enter() -> void:
	%ItemVisualsContainer3D.hide()
	#for control in root.docking_hidden_interfaces:
		#control.hide()

func update(delta: float) -> void:
	if root == null:
		print("Null root")
		return
	var input_motion_vector := PlayerController.get_input_motion_vector()
	
	var forward_amount := -input_motion_vector.y
	if forward_amount > 0.0:
		root.move_forward(forward_amount)
	
	root.turn(-input_motion_vector.x * delta)
