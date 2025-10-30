extends Label
class_name PropertyLabel


@export var target_node: Node
@export var target_property_name: String
@export var insertion_character: String = "*"

var raw_text: String = ""


func _ready() -> void:
	raw_text = text
	if target_property_name == "":
		printerr("Property name for " + name + " has not been set")
		return
	if insertion_character == "":
		printerr("Insertion character for " + name + " has not been set")
		return
	update_text()

func _process(_delta: float) -> void:
	update_text()

func update_text() -> void:
	text = raw_text.replace(insertion_character, str(target_node.get(target_property_name)))

