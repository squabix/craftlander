class_name TooltipLabel
extends Label

@export var interactor: Interactor3D
@export var visible_when_paused := false


func _process(_delta: float) -> void:
	if get_tree().paused and not visible_when_paused:
		hide()
		return

	if interactor == null:
		return
	var interactable := interactor.get_current_interactable()
	if interactable == null:
		hide()
		return
	text = interactable.get_tooltip()
	show()
