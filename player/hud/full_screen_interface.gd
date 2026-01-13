extends Control

@onready var crafting_environment: CraftingEnvironment = $CraftingMenu/CraftingEnvironment

const ACTION_PAUSE := "ui_cancel"
var is_paused := false

func _ready() -> void:
	update()

func update() -> void:
	visible = is_paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(ACTION_PAUSE):
		is_paused = !is_paused
		get_tree().paused = is_paused
		crafting_environment.is_crafting = is_paused
		update()
