extends Control

@onready var respawn_button: Button = $OptionsContainer/RespawnButton
@onready var quit_button: Button = $OptionsContainer/QuitButton

func _ready() -> void:
	hide()
	%Health.died.connect(show)
	%Health.revived.connect(hide)
	
	quit_button.pressed.connect(EventBus.trigger.bind("quit_to_title"))
