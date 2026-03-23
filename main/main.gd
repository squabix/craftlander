extends Node

@onready var title_screen_scene: PackedScene = load("res://menus/title_screen.tscn")
@onready var island_scenes: Array[PackedScene] = [
	load("res://levels/island0.tscn")
]

var title_screen: TitleScreen
var level: Node3D

func _ready() -> void:
	title_screen = $TitleScreen
	title_screen.started_new_game.connect(start_new_game)

func start_new_game(save: int) -> void:
	title_screen.queue_free()
	level = island_scenes[save].instantiate()
	add_child(level)
