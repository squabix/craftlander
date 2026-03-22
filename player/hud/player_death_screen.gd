extends Control

func _ready() -> void:
	hide()
	%Health.died.connect(show)
	%Health.revived.connect(hide)
