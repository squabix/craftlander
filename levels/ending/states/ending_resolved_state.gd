class_name EndingResolvedState
extends EndingState

const FLASH_COLOR := Color(1.0, 0.95, 0.85)
const FLASH_HOLD := 0.3
const FLASH_FADE := 1.5
const STATUS := "Defeated the Ghost Captain"

@export var finale_state := &"Finale"
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var vanish_timeout := 8.0

var _resolved := false


func _ready() -> void:
	EventBus.subscribe(&"treasure_chest_opened", on_chest_opened, tree_exiting)


func enter() -> void:
	_resolved = false
	encounter.captain.vanished.connect(resolve, CONNECT_ONE_SHOT)
	super()


func run() -> void:
	encounter.island.silence_cannons()
	SteamManager.update_status(STATUS)
	GameSave.mark_captain_defeated()

	await get_tree().create_timer(vanish_timeout, false, false, true).timeout
	resolve()


func resolve() -> void:
	if _resolved or not is_active:
		return
	_resolved = true

	encounter.hud.flash(FLASH_COLOR, FLASH_HOLD, FLASH_FADE)
	encounter.island.lift_curse()
	encounter.play_cue(null)
	encounter.island.sink_boats()
	encounter.end_lockdown()
	EventBus.trigger(&"captain_defeated")
	Main.root.save_current_game()


func on_chest_opened() -> void:
	if is_active and _resolved:
		go_to(finale_state)
