class_name DeletionAlarm
extends Node

signal deleted


func _process(_delta: float) -> void:
	if get_parent().is_queued_for_deletion():
		deleted.emit()
		set_process(false)
