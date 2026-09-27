class_name CollectedItemsList
extends VBoxContainer

const ENTRY_SCENE := preload("res://player/ui/collected_item_entry.tscn")
const MAX_ENTRIES := 5

@export var player: Player

var _entries: Array[CollectedItemEntry] = []


func _ready() -> void:
	for interactor in player.interactors:
		if not is_instance_valid(interactor):
			continue
		interactor.interacted_with.connect(_on_interacted_with)
	EventBus.subscribe(&"resource_harvested", _on_resource_harvested)


func _on_interacted_with(interactable: Interactable3D) -> void:
	if not interactable is ItemPickup3D:
		return
	if not interactable.is_queued_for_deletion():
		return # Pickup failed (inventory was full)
	_add_entry(interactable.item)


func _on_resource_harvested(payload: Dictionary) -> void:
	var source: Node = payload.get("source")
	if source != player:
		return
	var item: Item = payload.get("item")
	if item == null:
		return
	_add_entry(item)


func _add_entry(item: Item) -> void:
	var entry := ENTRY_SCENE.instantiate() as CollectedItemEntry
	add_child(entry)
	entry.setup(item)
	entry.expired.connect(_entries.erase.bind(entry))
	_entries.append(entry)

	if _entries.size() > MAX_ENTRIES:
		var oldest: CollectedItemEntry = _entries.pop_front()
		if is_instance_valid(oldest):
			oldest.expire_now()
