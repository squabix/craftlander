extends Node
class_name DeletionAlarm

signal deleted

func _process(_delta: float) -> void:
	if get_parent().is_queued_for_deletion():
		deleted.emit()
		set_process(false)
