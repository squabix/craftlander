extends Node
class_name Main

@onready var title_screen_scene: PackedScene = load("res://menus/title_screen.tscn")
@onready var island_scenes: Array[PackedScene] = [
	load("res://levels/island0.tscn")
]

static var title_screen: TitleScreen
static var level: Node3D

func _ready() -> void:
	load_title()
	EventBus.subscribe("quit_to_title", quit_to_title)

func start_new_game(save: int) -> void:
	title_screen.queue_free()
	level = island_scenes[save].instantiate()
	add_child(level)

func quit_level() -> void:
	level.queue_free()
	level = null

func quit_to_title() -> void:
	quit_level()
	load_title()

func load_title() -> void:
	title_screen = title_screen_scene.instantiate()
	add_child(title_screen)
	title_screen.started_new_game.connect(start_new_game)
