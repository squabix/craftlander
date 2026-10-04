class_name PickableResource
extends DestructibleResource

@export var interactable: Interactable3D


func _ready() -> void:
	super()
	if is_instance_valid(interactable):
		interactable.interacted_with.connect(_on_interacted_with)


func _on_interacted_with(source: Node) -> void:
	var to := get_damage_source_inventory(source)
	var item := inventory.get_item(inventory.get_random_index_weighted())
	if not is_instance_valid(to) or not to.has_room(item, 1):
		return

	give_random_item(to)
	Util.safe_free(self)
