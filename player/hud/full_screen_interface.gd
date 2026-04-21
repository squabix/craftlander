extends Control

signal updated_pause

@onready var crafting_menu: Control = $CraftingMenu
@onready var crafting_environment: CraftingEnvironment = $CraftingMenu/CraftingEnvironment
@onready var settings_menu: Menu = $SettingsMenu
@onready var settings_button: Button = $CraftingMenu/SettingsButton

const ACTION_PAUSE := "ui_cancel"
var is_paused := false

func _ready() -> void:
	update()
	%Health.died.connect(set_process.bind(false))
	%Health.revived.connect(set_process.bind(true))
	settings_button.pressed.connect(open_settings)

func open_settings() -> void:
	crafting_menu.hide()
	settings_menu.show()
	await settings_menu.backed_out
	settings_menu.hide()
	crafting_menu.show()

func update() -> void:
	visible = is_paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(ACTION_PAUSE):
		is_paused = !is_paused
		get_tree().paused = is_paused
		crafting_environment.is_crafting = is_paused
		update()
		updated_pause.emit()
