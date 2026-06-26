extends Control

signal updated_pause(to: bool)

const ACTION_PAUSE := "ui_cancel"

@export var crafting_menu: Control
@export var crafting_environment: CraftingEnvironment
@export var recipe_panel: Control
@export var settings_menu: Menu
@export var settings_button: Button
@export var health: Health

var is_paused := false
var can_update_pause := true

func _ready() -> void:
	update()
	health.died.connect(disable_update_pause)
	health.revived.connect(enable_update_pause)
	settings_button.pressed.connect(open_settings)

func open_settings() -> void:
	crafting_menu.hide()
	settings_menu.show()
	await settings_menu.backed_out
	settings_menu.hide()
	crafting_menu.show()

func enable_update_pause() -> void: can_update_pause = true
func disable_update_pause() -> void: can_update_pause = false

func update() -> void:
	visible = is_paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED

func pressed_pause() -> bool:
	return Input.is_action_just_pressed(ACTION_PAUSE)

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	crafting_environment.is_crafting = is_paused
	update()
	if is_paused == false:
		recipe_panel.show_types()
		recipe_panel.recipe_display.clear()
	updated_pause.emit(is_paused)

func _process(_delta: float) -> void:
	if can_update_pause and pressed_pause():
		toggle_pause()
