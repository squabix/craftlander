extends ItemDisplay

@export var crafting_environment: CraftingEnvironment
@export var craft_button: Button
@export var preview_rect: TextureRect
@export var preview_label: Label

@export_group("Pulse", "pulse")
@export var pulse_color := Color(1.5, 1.4, 0.7)
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var pulse_duration := 0.6

var _pulse_tween: Tween

func _ready() -> void:
	crafting_environment.grid_changed.connect(update)
	update()
	craft_button.pressed.connect(crafting_environment.craft)

	var craft_icon := ControllerIconTexture.new()
	craft_icon.path = &"craft"
	craft_button.icon = craft_icon
	craft_button.expand_icon = true

func update() -> void:
	var recipe := RecipeBook.get_recipe(crafting_environment.get_recipe_layout())
	if recipe == null:
		craft_button.disabled = true
		instance_override = null
		stop_pulse()
		return
	
	craft_button.disabled = false
	instance_override = recipe.result
	start_pulse()


func start_pulse() -> void:
	if is_instance_valid(_pulse_tween) and _pulse_tween.is_running():
		return

	_pulse_tween = craft_button.create_tween().set_loops()
	_pulse_tween.tween_property(craft_button, "modulate", pulse_color, pulse_duration).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(craft_button, "modulate", Color.WHITE, pulse_duration).set_trans(Tween.TRANS_SINE)


func stop_pulse() -> void:
	if is_instance_valid(_pulse_tween):
		_pulse_tween.kill()
	craft_button.modulate = Color.WHITE
