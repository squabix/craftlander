class_name TooltipDisplay
extends Control

const DEFAULT_FADE_SPEED: float = 0.1

static var identification: Identification = Identification.new()

@export var id: int
@export var label: Label
@export var visible_when_paused: bool

var should_be_visibile: bool = false
var current_tooltip: String


static func display(tooltip: String, display_id: int) -> void:
	if tooltip.is_empty():
		return
	var tooltip_display: TooltipDisplay = identification.fetch(display_id)
	if not is_instance_valid(tooltip_display):
		return
	tooltip_display.current_tooltip = tooltip
	tooltip_display.should_be_visibile = true


func _ready() -> void:
	identification.auto_register(self)


func _process(_delta: float) -> void:
	if not visible_when_paused and get_tree().paused:
		hide()
		return
	show()
	if is_instance_valid(label):
		label.text = current_tooltip
	if should_be_visibile:
		appear()
	else:
		disappear()
	should_be_visibile = false


func appear() -> void:
	modulate.a = move_toward(modulate.a, 1.0, DEFAULT_FADE_SPEED)


func disappear() -> void:
	modulate.a = move_toward(modulate.a, 0.0, DEFAULT_FADE_SPEED)
