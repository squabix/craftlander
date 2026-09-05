class_name TooltipLabel
extends RichTextLabel

@export var interactors: Array[Interactor3D]
@export var visible_when_paused := false
var _last_tooltip := ""


func _process(_delta: float) -> void:
	if get_tree().paused and not visible_when_paused:
		hide()
		return

	for interactor in interactors:
		var interactable := interactor.get_current_interactable()
		if interactable == null:
			continue
		show_tooltip(interactable.get_tooltip())
		return
	hide()


func show_tooltip(shown_text: String) -> void:
	show()
	if shown_text == _last_tooltip:
		return
	_last_tooltip = shown_text
	clear()
	add_text(shown_text)
