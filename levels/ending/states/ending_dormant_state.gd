class_name EndingDormantState
extends EndingState

@export var curse_state := &"Curse"
@export var finale_state := &"Finale"
@export var cue: MusicCue


func _ready() -> void:
	EventBus.subscribe(&"treasure_chest_touched", on_chest_touched, tree_exiting)
	EventBus.subscribe(&"treasure_chest_opened", on_chest_opened, tree_exiting)


func run() -> void:
	if not GameSave.is_captain_defeated():
		encounter.play_cue(cue)


func on_chest_touched(chest: TreasureChest) -> void:
	if not is_active:
		return

	encounter.chest = chest
	go_to(curse_state)


func on_chest_opened() -> void:
	if is_active and GameSave.is_captain_defeated():
		go_to(finale_state)
