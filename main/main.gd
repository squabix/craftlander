class_name Main
extends Node

const MAX_SLOT := 5
const ISLAND_SCENE_PATH_FORMAT := "res://levels/island_%s.tscn"
const SAVE_PATH_FORMAT := "user://save_slot_%s.tres"

static var root: Main:
	get:
		if root == null:
			printerr("Main root is null")
			root = Main.new()
		return root
static var current_save_slot := 0
static var loaded_save: Save:
	get:
		if loaded_save == null:
			return Save.new()
		return loaded_save
static var current_level_index := 0
static var base_seed := 0:
	set(to):
		base_seed = to
		seed(to)
		randi() # Throw away first generated number

var title_screen: TitleScreen
var level: Node3D

@onready var title_screen_scene: PackedScene = preload("res://menus/title_screen.tscn")
@onready var game_save: Script = preload("res://main/game_save.gd")


static func get_slot_path(slot: int) -> String:
	return SAVE_PATH_FORMAT % slot


static func is_saved(slot: int) -> bool:
	return ResourceLoader.exists(SAVE_PATH_FORMAT % slot)


func _ready() -> void:
	root = self
	load_title()
	EventBus.subscribe(&"quit_to_title", quit_to_title)


func load_level(index: int) -> void:
	var path := ISLAND_SCENE_PATH_FORMAT % index
	if not ResourceLoader.exists(path):
		printerr("Cannot load nonexistant level %s from %s" % index)
		return

	current_level_index = index

	clear()
	level = load(path).instantiate()
	NodeSaver.scene_root = level
	add_child(level)


func new_save() -> Save:
	return game_save.new()


func start_new_game(slot: int) -> void:
	if slot < 0 or slot >= MAX_SLOT:
		printerr("%s cannot start new game in invalid slot number: %s" % [self, slot])
		return
	loaded_save = new_save()
	loaded_save.base_seed = randi() # Give the new game a random seed
	base_seed = loaded_save.base_seed

	current_save_slot = slot
	save_game(slot)
	load_level(0)


func save_game(slot: int) -> void:
	if slot < 0 or slot >= MAX_SLOT:
		printerr("%s cannot save game to invalid slot number: %s" % [self, slot])
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
		printerr("Failed to save game to slot %s. Error: %s" % [slot, err])


func load_game(slot: int) -> void:
	if slot < 0 or slot >= MAX_SLOT:
		printerr("%s cannot load game from invalid slot number: %s" % [self, slot])
		return

	var path := get_slot_path(slot)
	var res := Save.load_from_disk(path)

	if res == null:
		printerr("Failed to load game: No save file found at %s" % path)
		return

	loaded_save = res
	base_seed = loaded_save.base_seed

	NodeSaver.save = loaded_save
	load_level(loaded_save.current_level_index)


func quit_level() -> void:
	clear()
	level = null


func quit_to_title() -> void:
	quit_level()
	load_title()
	MouseModeController.show()


func load_title() -> void:
	title_screen = title_screen_scene.instantiate()
	add_child(title_screen)
	title_screen.save_submenu.started_new_game.connect(start_new_game)
	title_screen.save_submenu.loaded_game.connect(load_game)


func clear() -> void:
	InventoryDropper3D.clear_dropped_pickups()
	for child in get_children():
		child.queue_free()

	title_screen = null

	if is_instance_valid(level):
		save_game(current_save_slot)
	level = null

	get_tree().paused = false
