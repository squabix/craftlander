extends Control

@export var respawn_button: Button
@export var quit_button: Button
@export var health: Health

func _ready() -> void:
	hide()
	health.died.connect(show)
	health.revived.connect(hide)
	
	if quit_button.pressed.is_connected(Main.root.quit_to_title):
		return
	quit_button.pressed.connect(Main.root.quit_to_title)
