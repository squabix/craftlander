class_name DeletionAlarm
extends Node

signal deleted


func _ready() -> void:
	tree_exiting.connect(deleted.emit)
