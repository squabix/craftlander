extends State

func enter() -> void:
	for control in get_parent().docking_hidden_interface:
		control.hide()
