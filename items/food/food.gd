extends Item
class_name Food

@export var health_restoration := 0.0
@export var hunger_restoration := 10.0
@export_range(0.0, 1.0) var sickness_chance := 0.0
@export_range(0.0, 1.0) var min_sickness := 0.05
@export_range(0.0, 1.0) var max_sickness := 0.15

class AteFoodEvent extends ItemEvent:
	@export var health_restoration: float
	@export var hunger_restoration: float
	@export var sickness: float
	
	func _init(event_health_restoration: float, event_hunger_restoration: float, event_sickness: float) -> void:
		name = "ate_food"
		health_restoration = event_health_restoration
		hunger_restoration = event_hunger_restoration
		sickness = event_sickness

func start_use() -> bool:
	var event := AteFoodEvent.new(
			health_restoration,
			hunger_restoration,
			randf_range(min_sickness, max_sickness) if randf() < sickness_chance else 0.0
		)
	trigger_event.call_deferred(event)
	return true
