extends Control

@export var inventory_selector: InventorySelector
@export var name_label: Label
@export var info_label: Label
@export var container: Control
@export var mouse_offset: Vector2

func _ready() -> void:
	inventory_selector.selected_instance_changed.connect(inspect_instance)

func _process(_delta: float) -> void:
	if inventory_selector.selected_index == -1 or inventory_selector.get_current_instance() == null:
		hide()
		return
	
	show()
	global_position = get_global_mouse_position() + Vector2.UP * size.y + mouse_offset

func inspect_instance(instance: ItemInstance) -> void:
	if instance == null:
		hide()
		return
	
	name_label.text = str(instance)
	info_label.text = get_info(instance.item)
	
	reset_size()

func get_info(item: Item) -> String:
	if item == null:
		return ""

	var lines: PackedStringArray = ["Type: %s" % item.type]

	if item is Food:
		if item.health_restoration > 0.0:
			lines.append("Heals: %s" % item.health_restoration)
		lines.append("Restores Hunger: %d%%" % roundi(item.hunger_restoration * 100.0))

	if item is HarvestingTool:
		if item.damage != null:
			lines.append("Damage: %s" % item.damage.base_amount)
		var harvest_range := get_harvest_range(item)
		if harvest_range > 0.0:
			lines.append("Range: %.1fm" % harvest_range)

	if item is ProjectileWeapon and item.damage != null:
		lines.append("Damage: %s" % item.damage.base_amount)

	if item.cooldown_mode != Item.CooldownMode.DISABLED and item.default_cooldown_length > 0.0:
		lines.append("Cooldown: %.1fs" % item.default_cooldown_length)

	return "\n".join(lines)

func get_harvest_range(item: HarvestingTool) -> float:
	if is_instance_valid(item.harvest_ray):
		return item.harvest_ray.target_position.length()
	if item.scene == null:
		return 0.0
	var temp := item.scene.instantiate()
	var ray := temp.get_node_or_null("HarvestRay") as RayCast3D
	var harvest_range := ray.target_position.length() if ray != null else 0.0
	temp.queue_free()
	return harvest_range
