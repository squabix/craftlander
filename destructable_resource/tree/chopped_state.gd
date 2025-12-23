extends State

func enter() -> void:
	Util.disable_all_colliders(root.trunk)
	root.trunk.hide()
