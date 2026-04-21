extends Control
class_name Menu

signal backed_out

func back() -> void:
	backed_out.emit()
