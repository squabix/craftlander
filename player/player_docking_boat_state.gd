extends State

func enter() -> void:
	%ItemVisualsContainer3D.hide()
	for control in get_parent().docking_hidden_interface:
		control.hide()
