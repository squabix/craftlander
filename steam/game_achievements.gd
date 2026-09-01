class_name GameAchievements
extends Node

const TRACKED_ENEMY_SCENES: Array[String] = [
	"res://entities/enemies/bee/bee.tscn",
	"res://entities/enemies/rootling/rootling.tscn",
	"res://entities/enemies/skeleton/skeleton.tscn",
	"res://entities/enemies/little_talus/little_talus.tscn",
	"res://entities/enemies/shroomoid/shroomoid.tscn",
]

const CRAFT_ACHIEVEMENTS: Dictionary[String, StringName] = {
	"res://items/weapons/mushroom_staff/mushroom_staff_item.tres": SteamIDs.ACH_CRAFT_MUSHROOM_STAFF,
}

const HUNTER_KILL_THRESHOLD := 50
const CLOSE_CALL_MAX_HP_PERCENT := 0.1


func _ready() -> void:
	EventBus.subscribe(&"enemy_died", _on_enemy_died)
	EventBus.subscribe(&"player_died", _on_player_died)
	EventBus.subscribe(&"player_survived_hurt", _on_player_survived_hurt)
	EventBus.subscribe(&"item_crafted", _on_item_crafted)
	EventBus.subscribe(&"island_populated", _on_island_populated)
	EventBus.subscribe(&"treasure_chest_opened", _on_treasure_chest_opened)


func _on_enemy_died(entity: Entity3D) -> void:
	if not entity.scene_file_path in TRACKED_ENEMY_SCENES:
		return

	SteamManager.unlock_achievement(SteamIDs.ACH_FIRST_BLOOD)
	SteamManager.increment_stat(SteamIDs.STAT_ENEMIES_KILLED)
	if SteamManager.get_stat(SteamIDs.STAT_ENEMIES_KILLED) >= HUNTER_KILL_THRESHOLD:
		SteamManager.unlock_achievement(SteamIDs.ACH_HUNTER)


func _on_player_died(was_in_water: bool) -> void:
	SteamManager.increment_stat(SteamIDs.STAT_DEATHS)
	if was_in_water:
		SteamManager.unlock_achievement(SteamIDs.ACH_TAKE_A_BATH)


func _on_player_survived_hurt(hp_percent: float) -> void:
	if hp_percent <= CLOSE_CALL_MAX_HP_PERCENT:
		SteamManager.unlock_achievement(SteamIDs.ACH_CLOSE_CALL)


func _on_item_crafted(item: Item) -> void:
	SteamManager.unlock_achievement(SteamIDs.ACH_FIRST_CRAFT)
	SteamManager.increment_stat(SteamIDs.STAT_ITEMS_CRAFTED)

	var item_path := item.resource_path
	if item_path in CRAFT_ACHIEVEMENTS:
		SteamManager.unlock_achievement(CRAFT_ACHIEVEMENTS[item_path])


func _on_island_populated() -> void:
	SteamManager.unlock_achievement(SteamIDs.ACH_FIRST_ISLAND)
	SteamManager.increment_stat(SteamIDs.STAT_ISLANDS_EXPLORED)


func _on_treasure_chest_opened() -> void:
	SteamManager.unlock_achievement(SteamIDs.ACH_TREASURE_HUNTER)
