extends ItemVisualsContainer3D

func _on_controller_3d_updated_entity(to: Entity3D) -> void:
	visible = to.type != "boat"
