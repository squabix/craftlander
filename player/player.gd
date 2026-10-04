class_name Player
extends Entity3D

const DEFAULT_HEAD_HEIGHT := 1.4
const CROUCHED_HEAD_HEIGHT := 0.7
const SWIMMING_HEAD_HEIGHT := 0.85
const HEAD_SPEED := 0.1
const HURT_SHAKE_TRAUMA := 0.4

@export_group("Components")
@export var movement_state_machine: StateMachine

@export_subgroup("3D")
@export var head: Node3D
@export var camera: Camera3D
@export var camera_shake: CameraShake3D
@export var interactors: Array[Interactor3D]

@export_subgroup("Screen Effects")
@export var vignette: CanvasItem
@export var hurt_effect_trigger: SignalTrigger
@export var low_health_indicator: LowHealthIndicator

@export_subgroup("Control")
@export var respawn_button: Button
@export var boat_menu: BoatMenu
@export var pause_menu: PauseMenu
@export var docking_hidden_interfaces: Array[Control] = []
@export var boat_compass_tracker: BoatCompassTracker
@export var enemy_compass_tracker: EnemyCompassTracker
@export var hud: Control
@export var hotbar_interface: Control
@export var player_bars: Control
@export var compass: Control
@export var viewmodel_container: Control

@export_group("Inventory")
@export var item_holder: InventoryHolder3D
@export var dropper: InventoryDropper3D
@export var inventory_saver: NodeSaver

@export_group("Stats")
@export var health: Health
@export var health_saver: NodeSaver
@export var hunger: Hunger
@export var hunger_saver: NodeSaver
@export var stamina: Stamina

@export_group("Audio")
@export var steps_player: CharacterAudioStreamPlayer3D
@export var swim_player: CharacterAudioStreamPlayer3D
@export var eat_player: AudioStreamPlayer

@export_group("Min Spawn", "min_spawn")
@export_range(0.0, 1.0) var min_spawn_health_ratio := 0.3
@export_range(0.0, 1.0) var min_spawn_hunger_ratio := 0.3

@export_group("Drowning", "drowning")
@export_custom(PROPERTY_HINT_NONE, "suffix:dp") var drowning_damage := 25.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var drowning_interval := 1.0

var is_in_water := false
var cutscene_locked := false
var drowning_cooldown := 0.0


func _ready() -> void:
	item_holder.item_event_triggered.connect(
		func(event: ItemEvent) -> void:
			if event is Food.AteFoodEvent:
				health.hp += event.health_restoration
				hunger.value += event.hunger_restoration
				eat_player.play()
			elif event is CandyBoomerangWeapon.ReturnedEvent:
				item_holder.selector.inventory.add_item(event.item, 1)
	)
	respawn_button.pressed.connect(respawn)
	health.died.connect(die)
	health.survived_hurt.connect(_on_survived_hurt)
	health.was_hurt.connect(_on_was_hurt)
	inventory_saver.finished_load.connect(item_holder.selector.update_current_instance, CONNECT_ONE_SHOT)
	health_saver.finished_load.connect(_on_health_loaded, CONNECT_ONE_SHOT)
	hunger_saver.finished_load.connect(_on_hunger_loaded, CONNECT_ONE_SHOT)

	camera.fov = GameSettings.config.get_value("gameplay", "fov", camera.fov)
	apply_screen_effect_settings()


func _on_health_loaded() -> void:
	health.hp = maxf(health.hp, health.max_hp * min_spawn_health_ratio)
	health.hp_changed.emit()


func _on_hunger_loaded() -> void:
	hunger.value = maxf(hunger.value, min_spawn_hunger_ratio)


func _process(delta: float) -> void:
	adjust_head()
	update_drowning(delta)
	update_hud_visibility()


func update_drowning(delta: float) -> void:
	if not is_in_water or stamina.is_usable():
		drowning_cooldown = 0.0
		return

	drowning_cooldown -= delta
	if drowning_cooldown > 0.0:
		return

	drowning_cooldown = drowning_interval
	health.hurt(drowning_damage)


func set_character_stream_player(to: CharacterAudioStreamPlayer3D) -> void:
	steps_player.disabled = steps_player != to
	swim_player.disabled = swim_player != to


func get_target_head_height() -> float:
	if movement_state_machine.is_currently(&"Crouching"):
		return CROUCHED_HEAD_HEIGHT
	if is_in_water:
		return SWIMMING_HEAD_HEIGHT
	return DEFAULT_HEAD_HEIGHT


func adjust_head() -> void:
	head.position.y = lerp(
		head.position.y,
		get_target_head_height(),
		HEAD_SPEED,
	)


func drop_selected_item() -> void:
	if cutscene_locked:
		return
	dropper.drop_index(item_holder.selector.selected_index)


func use_item() -> void:
	if cutscene_locked:
		return
	item_holder.use_item()


func interact() -> void:
	if cutscene_locked:
		return
	for interactor in interactors:
		if interactor.interact() != null:
			return


func die() -> void:
	get_tree().paused = true
	MouseModeController.show()
	EventBus.trigger(&"player_died", is_in_water)


func _on_survived_hurt() -> void:
	EventBus.trigger(&"player_survived_hurt", health.to_percent_max(health.hp))


func _on_was_hurt() -> void:
	camera_shake.add_trauma(HURT_SHAKE_TRAUMA)


func apply_screen_effect_settings() -> void:
	vignette.visible = GameSettings.config.get_value("gameplay", "vignette_enabled", true)
	var hurt_effect_enabled: bool = GameSettings.config.get_value("gameplay", "hurt_effect_enabled", true)
	hurt_effect_trigger.disabled = not hurt_effect_enabled
	low_health_indicator.enabled = hurt_effect_enabled


func respawn() -> void:
	Main.root.respawn_game(Main.current_save_slot)


func set_cutscene_locked(locked: bool) -> void:
	cutscene_locked = locked
	frozen = locked
	
	var controller := EntityController3D.get_controller(self) as PlayerController
	if is_instance_valid(controller):
		controller.input_locked = locked
	else:
		Util.node_error("%s cannot lock input without a controller", self)
	
	update_hud_visibility()
	
	if is_instance_valid(pause_menu):
		if locked:
			pause_menu.disable_update_pause()
		else:
			pause_menu.enable_update_pause()


func update_hud_visibility() -> void:
	var hide_for_trailer := Main.trailer_mode and not get_tree().paused
	if is_instance_valid(hud):
		hud.visible = not (hide_for_trailer or cutscene_locked or get_tree().paused)
	if is_instance_valid(hotbar_interface):
		hotbar_interface.visible = not (hide_for_trailer or cutscene_locked)

	# Bars and compass stay hidden in trailer mode even while paused
	if is_instance_valid(player_bars):
		player_bars.visible = not (Main.trailer_mode or cutscene_locked)
	if is_instance_valid(compass):
		compass.visible = not (Main.trailer_mode or cutscene_locked)
	if is_instance_valid(viewmodel_container):
		viewmodel_container.visible = not cutscene_locked
	if is_instance_valid(item_holder):
		item_holder.visible = not cutscene_locked

	health.immortal = Main.trailer_mode


func _on_pause_interface_updated_pause(to: bool) -> void:
	update_hud_visibility()
	if to == true:
		return
	await get_tree().process_frame
	item_holder.selector.update_current_instance()
