extends Menu
class_name AboutMenu

@export var text_scroll: ScrollContainer

@export_group("Scrolling", "scroll")
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var scroll_speed := 300.0


func _ready() -> void:
	super()
	set_process(false)


func _process(delta: float) -> void:
	text_scroll.scroll_vertical += roundi(Input.get_axis(&"ui_up", &"ui_down") * scroll_speed * delta)


func open() -> void:
	text_scroll.scroll_vertical = 0
	set_process(true)


func close() -> void:
	set_process(false)
