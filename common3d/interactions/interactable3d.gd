class_name Interactable3D
extends Area3D

enum PostInteractionMode {NOTHING, DISABLE, FREE}

signal interacted_with(source: Node)

@export var enabled := true:
	set(to):
		enabled = to
		if visible_as_enabled:
			visible = enabled
@export var channel := 0
@export var visible_as_enabled := false
@export var post_interaction_mode := PostInteractionMode.NOTHING

@export_group("Tooltips", "tooltip")
@export var tooltip_enabled := ""
@export var tooltip_disabled := ""


func enable() -> void:
	enabled = true


func disable() -> void:
	enabled = false


func interact(source: Node, _etc: Dictionary = { }) -> void:
	interacted_with.emit(source)
	match post_interaction_mode:
		PostInteractionMode.NOTHING:
			pass
		PostInteractionMode.DISABLE:
			disable()
		PostInteractionMode.FREE:
			queue_free()


func get_tooltip() -> String:
	return tooltip_enabled if enabled else tooltip_disabled
