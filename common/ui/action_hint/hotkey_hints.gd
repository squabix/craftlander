extends GridContainer

@export var item_holder: ItemHolder3D
@export var use_hint: ActionHint


func _ready() -> void:
	item_holder.updated_instance.connect(_on_updated_instance)
	_on_updated_instance(item_holder.held_item_instance)


func _on_updated_instance(_instance: ItemInstance) -> void:
	var item := item_holder.get_held_item()
	var action_name: StringName = item.use_action_name if item != null else &""
	use_hint.visible = not action_name.is_empty()
	use_hint.hint_text = action_name
