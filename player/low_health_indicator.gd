class_name LowHealthIndicator
extends Node

@export var health: Health
@export var indicator: CanvasItem
@export var animation_player: AnimationPlayer
@export var animation_name := &"pulse"

@export_group("Threshold", "threshold")
@export_range(0.0, 1.0) var threshold_ratio := 0.25

var enabled := true:
	set(to):
		enabled = to
		refresh()

var _is_showing := false


func _ready() -> void:
	health.died.connect(refresh)
	health.revived.connect(refresh)
	refresh()


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	var should_show := enabled and not health.dead and health.hp <= health.max_hp * threshold_ratio
	if should_show == _is_showing:
		return

	_is_showing = should_show
	indicator.visible = should_show
	if should_show:
		animation_player.play(animation_name)
	else:
		animation_player.stop()
