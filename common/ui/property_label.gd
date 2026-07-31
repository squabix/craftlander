class_name PropertyLabel
extends Label

@export var target_node: Node
@export var target_property_name: StringName
@export var insertion_character: String = "*"

var raw_text: String = ""


func _ready() -> void:
	raw_text = text
	if target_property_name == "":
		Util.node_error("Property name for %s has not been set", self)
		return
	if insertion_character == "":
		Util.node_error("Insertion character for %s has not been set", self)
		return
	update_text()


func _process(_delta: float) -> void:
	update_text()


func update_text() -> void:
	text = raw_text.replace(insertion_character, str(target_node.get(target_property_name)))
