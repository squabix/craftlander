class_name AutoSaver
extends Timer

signal saved

@export var player: Player
@export var health: Health
@export var hunger: Hunger

@export_group("Requirements", "requirement")
@export_range(0.0, 1.0) var requirement_health_fraction := 0.6
@export_range(0.0, 1.0) var requirement_hunger_fraction := 0.6

@export_group("Retry", "retry")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var retry_interval := 10.0

var interval := 0.0


func _ready() -> void:
	interval = wait_time
	timeout.connect(_on_timeout)


func can_save() -> bool:
	return (
		not Main.saving_locked
		and not Main.autosave_locked
		and not player.cutscene_locked
		and not health.dead
		and health.hp > health.max_hp * requirement_health_fraction
		and hunger.value > requirement_hunger_fraction
	)


func _on_timeout() -> void:
	if not can_save():
		start(retry_interval)
		return

	Main.root.save_current_game()
	saved.emit()
	start(interval)
