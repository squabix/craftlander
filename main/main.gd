class_name Main
extends Node

signal difficulty_changed(value: int)

const MAX_SLOT := 5
const ISLAND_SCENE_PATH_FORMAT := "res://levels/island_%s.tscn"
const SAVE_PATH_FORMAT := "user://save_slot_%s.res"

static var root: Main:
	get:
		if root == null:
			push_error("Main root is null")
			root = Main.new()
		return root
static var current_save_slot := 0
static var loaded_save: Save:
	get:
		if loaded_save == null:
			return preload("res://main/game_save.gd").new()
		return loaded_save
	set(to):
		loaded_save = to
		is_save_loaded = true
static var is_save_loaded := false
static var current_level_index := 0
static var base_seed := 0:
	set(to):
		base_seed = to
		seed(to)
		randi() # Throw away first generated number

var title_screen: TitleScreen
var level: Node3D

@onready var title_screen_path := "res://menus/title_screen.tscn"
@onready var game_save: Script = preload("res://main/game_save.gd")
@onready var loading_screen_scene: PackedScene = preload("res://main/loading_screen.tscn")

var loading_screen: LoadingScreen


static func get_slot_path(slot: int) -> String:
	return SAVE_PATH_FORMAT % slot


static func is_saved(slot: int) -> bool:
	return ResourceLoader.exists(SAVE_PATH_FORMAT % slot)


func _ready() -> void:
	root = self
	load_title()


func advance_loading_step() -> String:
	if not is_instance_valid(loading_screen):
		Util.node_error("Cannot advance loading step of invalid loading screen (%s)", loading_screen)
		return ""
	var step := loading_screen.advance_step()
	await get_tree().process_frame
	return step


func load_level(index: int) -> void:
	var path := ISLAND_SCENE_PATH_FORMAT % index
	if not ResourceLoader.exists(path):
		Util.node_error("Cannot load nonexistant level %s from %s", index, path)
		return

	current_level_index = index
	
	var loaded_level := await load_scene(path)
	if loaded_level == null:
		push_error("Cannot load null level")
		return
	
	clear()
	level = loaded_level
	print("Loaded level %s" % level)
	NodeSaver.scene_root = level
	add_child(level)


func load_scene(path: String) -> Node:
	Util.safe_free(loading_screen)
	loading_screen = loading_screen_scene.instantiate()
	add_child(loading_screen)
	print("Loading %s..." % path)
	
	var scene := (await loading_screen.load_resource(path) as PackedScene)
	return scene.instantiate() if scene != null else null


func new_save() -> Save:
	return game_save.new()


func start_new_game(slot: int, seed_value: int, difficulty: int) -> void:
	if slot < 0 or slot >= MAX_SLOT:
		Util.node_error("Cannot start new game in invalid slot number: %s", slot)
		return
	loaded_save = new_save()
	loaded_save.base_seed = seed_value
	base_seed = loaded_save.base_seed
	set_difficulty(difficulty)

	current_save_slot = slot
	save_game(slot)
	load_level(0)


func set_difficulty(value: int) -> void:
	loaded_save.difficulty = value
	difficulty_changed.emit(value)


func save_current_game() -> void:
	save_game(current_save_slot)


func save_game(slot: int) -> void:
	if slot < 0 or slot >= MAX_SLOT:
		Util.node_error("%s cannot save game to invalid slot number: %s", slot)
		return

	if loaded_save == null:
		loaded_save = new_save()

	loaded_save.current_level_index = current_level_index
	loaded_save.base_seed = base_seed

	NodeSaver.save = loaded_save
	NodeSaver.save_all()

	var err := loaded_save.write_to_disk(get_slot_path(slot))
	if err == OK:
		print("Successfully saved game to slot %s" % slot)
	else:
		Util.node_error("Failed to save game to slot %s. Error: %s", slot, err)


func load_game(slot: int) -> void:
	if slot < 0 or slot >= MAX_SLOT:
		Util.node_error("%s cannot load game from invalid slot number: %s", self, slot)
		return

	var path := get_slot_path(slot)
	var res := Save.load_from_disk(path)

	if res == null:
		Util.node_error("Failed to load game: No save file found at %s", path)
		return

	loaded_save = res
	current_save_slot = slot
	base_seed = loaded_save.base_seed

	NodeSaver.save = loaded_save
	load_level(loaded_save.current_level_index)


func quit_level() -> void:
	clear()
	level = null


func quit_to_title() -> void:
	save_current_game()
	quit_level()
	await load_title()
	MouseModeController.show()


func load_title() -> void:
	title_screen = await load_scene(title_screen_path)
	add_child(title_screen)
	title_screen.save_submenu.started_new_game.connect(start_new_game)
	title_screen.save_submenu.loaded_game.connect(load_game)


func clear() -> void:
	InventoryDropper3D.clear_dropped_pickups()
	for child in get_children():
		if child == loading_screen:
			continue
		child.queue_free()

	title_screen = null

	if is_instance_valid(level):
		save_game(current_save_slot)
	level = null

	get_tree().paused = false
