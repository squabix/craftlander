extends State

func enter() -> void:
	%ItemVisualsContainer3D.hide()
	#for control in root.docking_hidden_interfaces:
		#control.hide()
