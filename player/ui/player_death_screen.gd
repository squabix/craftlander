extends Control

@onready var respawn_button: Button = $OptionsContainer/RespawnButton
@onready var quit_button: Button = $OptionsContainer/QuitButton

func _ready() -> void:
	hide()
	%Health.died.connect(show)
	%Health.revived.connect(hide)
	
	var trigger_quit := EventBus.trigger.bind(&"quit_to_title")
	if quit_button.pressed.is_connected(trigger_quit):
		return
	quit_button.pressed.connect(EventBus.trigger.bind(&"quit_to_title"))
