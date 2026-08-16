class_name PauseMenu
extends Menu

signal updated_pause(to: bool)

const ACTION_PAUSE := &"pause"

@export var crafting_environment: CraftingEnvironment
@export var recipe_panel: Control
@export var health: Health
@export var settings_menu: Menu

@export_group("Options Buttons", "button")
@export var button_save: Button
@export var button_settings: Button
@export var button_quit: Button

var is_paused := false
var can_update_pause := true


func _ready() -> void:
	super()
	update_pause(false)

	if is_instance_valid(health):
		health.died.connect(disable_update_pause)
		health.revived.connect(enable_update_pause)

	# Connect options buttons
	if is_instance_valid(button_save):
		button_save.pressed.connect(Main.root.save_current_game)
	if is_instance_valid(button_settings):
		button_settings.pressed.connect(open_submenu.bind(settings_menu))
	if is_instance_valid(button_quit):
		button_quit.pressed.connect(Main.root.quit_to_title)


func _unhandled_input(event: InputEvent) -> void:
	if not can_update_pause:
		return
	if not event.is_action_pressed(ACTION_PAUSE):
		return
	if is_instance_valid(active_submenu):
		return
	update_pause(true)


func enable_update_pause() -> void:
	can_update_pause = true


func disable_update_pause() -> void:
	can_update_pause = false


func open() -> void:
	auto_focus()
	if is_instance_valid(recipe_panel):
		recipe_panel.show_types()
		recipe_panel.recipe_display.clear()


func back() -> void:
	update_pause(false)
	backed_out.emit()


func update_pause(to: bool) -> void:
	if Menu.lock_frame():
		return

	is_paused = to
	visible = is_paused
	get_tree().paused = is_paused
	if is_instance_valid(crafting_environment):
		crafting_environment.is_crafting = is_paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED
	updated_pause.emit(is_paused)

	# Open/close depending on pause
	if is_paused:
		open()
	else:
		close()
