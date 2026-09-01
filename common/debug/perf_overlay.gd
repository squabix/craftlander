extends CanvasLayer

@export var panels_root: Control
@export var toggle_action := &"toggle_perf_overlay"

func _ready() -> void:
	panels_root.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_action):
		panels_root.visible = not panels_root.visible
