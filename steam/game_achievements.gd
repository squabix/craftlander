class_name GameAchievements
extends Node

const CRAFT_ACHIEVEMENTS: Dictionary[String, StringName] = {
	"res://items/weapons/mushroom_staff/mushroom_staff_item.tres": SteamIDs.ACH_MUSHROOM_STAFF,
	"res://items/weapons/ice_staff/ice_staff_item.tres": SteamIDs.ACH_ICE_STAFF,
	"res://items/weapons/slime_staff/slime_staff_item.tres": SteamIDs.ACH_SLIME_STAFF,
	"res://items/tools/diamond/diamond_pickaxe/diamond_pickaxe_item.tres": SteamIDs.ACH_DIAMOND_AGE,
	"res://items/weapons/ice_club/ice_club_item.tres": SteamIDs.ACH_BATTER_UP,
}

const HUNTER_KILL_THRESHOLD := 30
const SLAYER_KILL_THRESHOLD := 100
const LUMBERJACK_TREE_THRESHOLD := 50
const CLOSE_CALL_MAX_HP_PERCENT := 0.1
const SURVIVE_NIGHTS_THRESHOLD := 10


func _ready() -> void:
	EventBus.subscribe(&"enemy_died", _on_enemy_died)
	EventBus.subscribe(&"player_died", _on_player_died)
	EventBus.subscribe(&"player_survived_hurt", _on_player_survived_hurt)
	EventBus.subscribe(&"item_crafted", _on_item_crafted)
	EventBus.subscribe(&"tree_chopped", _on_tree_chopped)
	EventBus.subscribe(&"bee_nest_destroyed", _on_bee_nest_destroyed)
	EventBus.subscribe(&"island_populated", _on_island_populated)
	EventBus.subscribe(&"treasure_chest_opened", _on_treasure_chest_opened)
	EventBus.subscribe(&"boat_upgraded", _on_boat_upgraded)
	EventBus.subscribe(&"game_beaten", _on_game_beaten)


func _on_enemy_died(_entity: Entity3D) -> void:
	SteamManager.increment_stat(SteamIDs.STAT_ENEMIES_KILLED)
	var kills := SteamManager.get_stat(SteamIDs.STAT_ENEMIES_KILLED)
	if kills >= HUNTER_KILL_THRESHOLD:
		SteamManager.unlock_achievement(SteamIDs.ACH_HUNTER)
	if kills >= SLAYER_KILL_THRESHOLD:
		SteamManager.unlock_achievement(SteamIDs.ACH_SLAYER)


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


func _on_tree_chopped() -> void:
	SteamManager.increment_stat(SteamIDs.STAT_TREES_CHOPPED)
	if SteamManager.get_stat(SteamIDs.STAT_TREES_CHOPPED) >= LUMBERJACK_TREE_THRESHOLD:
		SteamManager.unlock_achievement(SteamIDs.ACH_LUMBERJACK)


func _on_bee_nest_destroyed() -> void:
	SteamManager.unlock_achievement(SteamIDs.ACH_HONEY_THIEF)


func _on_island_populated() -> void:
	SteamManager.increment_stat(SteamIDs.STAT_ISLANDS_EXPLORED)


func _on_treasure_chest_opened() -> void:
	SteamManager.unlock_achievement(SteamIDs.ACH_TREASURE_HUNTER)


func _on_boat_upgraded(_level: int) -> void:
	SteamManager.unlock_achievement(SteamIDs.ACH_SET_SAIL)


func _on_game_beaten() -> void:
	SteamManager.unlock_achievement(SteamIDs.ACH_CURSE_BROKEN)


func on_day_survived() -> void:
	SteamManager.increment_stat(SteamIDs.STAT_DAYS_SURVIVED)
	if SteamManager.get_stat(SteamIDs.STAT_DAYS_SURVIVED) >= SURVIVE_NIGHTS_THRESHOLD - 1:
		SteamManager.unlock_achievement(SteamIDs.ACH_SURVIVE_10_NIGHTS)
