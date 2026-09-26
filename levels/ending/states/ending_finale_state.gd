class_name EndingFinaleState
extends EndingState

const CHEST_LOOK_HEIGHT := 0.7
const CHEST_LOOK_TIME := 0.6
const FADE_TIME := 1.5

@export var closing_line := "The captain rests. The sea is quiet again."
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var line_time := 4.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var open_settle := 1.0
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var zoom_fov := 55.0


func run() -> void:
	encounter.cutscene.begin()
	if not await wait(frame_chest()):
		return

	await encounter.hud.show_line(closing_line, line_time)
	if not is_alive():
		return

	await encounter.cutscene.fade_out(Color.BLACK, FADE_TIME)
	if not is_alive():
		return

	await encounter.cutscene.set_letterbox(false, 0.0)
	if not is_alive():
		return

	finish_game()
	await encounter.hud.play_credits()
	if is_alive():
		Main.root.quit_to_title()


func frame_chest() -> float:
	var chest := encounter.chest
	if not is_instance_valid(chest):
		chest = Util.find_child_of_class(encounter.get_parent(), &"TreasureChest") as TreasureChest
	if not is_instance_valid(chest):
		return open_settle

	var open_time := open_settle + chest.anim_player.get_animation(&"open").length
	encounter.cutscene.look_toward(chest.global_position + Vector3.UP * CHEST_LOOK_HEIGHT, CHEST_LOOK_TIME)
	encounter.cutscene.zoom_to(zoom_fov, open_time)
	return open_time


func finish_game() -> void:
	GameSave.mark_game_beaten()
	EventBus.trigger(&"game_beaten")
	Main.saving_locked = false
