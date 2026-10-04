extends Item
class_name Food

@export var health_restoration := 0.0
@export_range(0.0, 1.0) var hunger_restoration := 0.1

@export_group("Eating", "eating")
@export_range(0.0, 1.0) var eating_full_fraction := 0.95

class AteFoodEvent extends ItemEvent:
	@export var health_restoration: float
	@export var hunger_restoration: float
	
	func _init(event_health_restoration: float, event_hunger_restoration: float) -> void:
		name = &"ate_food"
		health_restoration = event_health_restoration
		hunger_restoration = event_hunger_restoration

func can_use() -> bool:
	var player := root as Player
	if player == null:
		return true
	var health_full := player.health.hp >= player.health.max_hp * eating_full_fraction
	var hunger_full := player.hunger.value >= eating_full_fraction
	return not (health_full and hunger_full)


func start_use() -> bool:
	var event := AteFoodEvent.new(
			health_restoration,
			hunger_restoration
		)
	trigger_event.call_deferred(event)
	return true
