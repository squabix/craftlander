class_name IconTooltipLabel
extends TooltipLabel

@export var interact_action := &"interact"
@export var icon_size := 20
@export var icon_text_seperator := " "

var _interact_icon := ControllerIconTexture.new()


func _ready() -> void:
	_interact_icon.path = interact_action


func show_tooltip(shown_text: String) -> void:
	show()
	if shown_text == _last_tooltip:
		return
	_last_tooltip = shown_text
	clear()
	add_image(_interact_icon, icon_size, icon_size, Color.WHITE, INLINE_ALIGNMENT_CENTER)
	add_text(icon_text_seperator + shown_text)
