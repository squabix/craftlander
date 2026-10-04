extends Node

enum Tier { TOAST, POPUP }

const LOW_HUNGER_THRESHOLD := 0.35
const SPRINT_HINT_HOLD_DURATION := 1.5 # s
const WELCOME_DELAY := 2.0 # s
const COPPER_ITEM_NAME := &"Copper Chunk"

const WEAK_TOOL_STEPS: Dictionary[StringName, StringName] = {
	&"pickaxe": &"weak_pickaxe",
	&"axe": &"weak_axe",
}

const STEPS: Dictionary[StringName, Dictionary] = {
	&"welcome_goal": {
		"tier": Tier.POPUP,
		"title": "You Are Stranded!",
		"text": "Gather resources, craft better tools and weapons, and upgrade your boat at the dock so you can sail to new islands. Keep sailing until you reach the final island.",
	},
	&"item_collecting": {
		"tier": Tier.TOAST,
		"text": "Pick up items you find around the island to add them to your inventory.",
		"icon_action": &"interact",
	},
	&"harvesting": {
		"tier": Tier.TOAST,
		"text": "Attack trees, rocks, and bushes to break them apart and collect resources you'll need to craft tools and gear.",
		"icon_action": &"use_primary",
	},
	&"sprinting": {
		"tier": Tier.TOAST,
		"text": "Hold Sprint while moving forward to run faster. Sprinting uses Stamina.",
		"icon_action": &"sprint",
	},
	&"crafting_intro": {
		"tier": Tier.TOAST,
		"text": "Open your backpack to craft. Follow your recipe book, place ingredients in the crafting grid, then press CRAFT.",
		"icon_action": &"pause",
		"prerequisite": &"harvesting",
	},
	&"copper_collected": {
		"tier": Tier.TOAST,
		"text": "Stronger materials let you craft stronger tools and gear. Keep exploring and gathering to upgrade your equipment."
	},
	&"first_weapon_crafted": {
		"tier": Tier.POPUP,
		"title": "Danger",
		"text": "You are now equipped to defend yourself from danger, but watch out: monsters have noticed you.",
		"prerequisite": &"item_collecting",
	},
	&"low_hunger": {
		"tier": Tier.TOAST,
		"text": "Your hunger is running low. Eat food to keep it from reaching zero.",
	},
	&"first_hit_taken": {
		"tier": Tier.TOAST,
		"text": "You are under attack! Fight back with your equipped weapon.",
		"icon_action": &"use_primary",
		"prerequisite": &"first_weapon_crafted",
	},
	&"boat_menu_opened": {
		"tier": Tier.POPUP,
		"title": "Sailing",
		"text": "Collect the listed resources to upgrade your ship and travel to the next island.",
	},
	&"weak_pickaxe": {
		"tier": Tier.TOAST,
		"text": "Your pickaxe isn't strong enough to mine this. Craft a stronger pickaxe from better materials.",
	},
	&"weak_axe": {
		"tier": Tier.TOAST,
		"text": "Your axe isn't strong enough to chop this down. Craft a stronger axe from better materials.",
	},
}

var _player: Player
var _movement_hold_time := 0.0


func _ready() -> void:
	EventBus.subscribe(&"item_crafted", _on_item_crafted)
	EventBus.subscribe(&"player_survived_hurt", _on_player_survived_hurt)
	EventBus.subscribe(&"resource_harvested", _on_resource_harvested)
	EventBus.subscribe(&"resource_resisted", _on_resource_resisted)
	EventBus.subscribe(&"player_boat_docked", _on_player_boat_docked)
	get_tree().node_added.connect(_on_node_added)


func _process(delta: float) -> void:
	if not get_tree().paused:
		_update_sprint_hint(delta)


func has_completed(step_id: StringName) -> bool:
	if not Main.is_save_loaded or Main.loaded_save == null:
		return false
	return Main.loaded_save.tutorial_steps_completed.get(step_id, false)


func are_hints_enabled() -> bool:
	return GameSettings.config.get_value("gameplay", "tutorial_hints_enabled", true)


func complete_step(step_id: StringName) -> void:
	if not step_id in STEPS or has_completed(step_id):
		return
	if not Main.is_save_loaded or Main.loaded_save == null:
		return

	var step: Dictionary = STEPS[step_id]
	var prerequisite: StringName = step.get("prerequisite", &"")
	if not prerequisite.is_empty() and not has_completed(prerequisite):
		return

	Main.loaded_save.tutorial_steps_completed[step_id] = true
	EventBus.trigger(&"tutorial_step_completed", step_id)

	if not are_hints_enabled() or Main.trailer_mode:
		return

	match int(step.get("tier", Tier.TOAST)):
		Tier.TOAST:
			HintToast.display(step.get("text", ""), step.get("icon_action", &""))
		Tier.POPUP:
			PopupDisplay.display(step.get("text", ""), step.get("title", ""))


func _update_sprint_hint(delta: float) -> void:
	if has_completed(&"sprinting"):
		return

	var is_moving := (
		Input.is_action_pressed(&"move_forward")
			or Input.is_action_pressed(&"move_backward")
			or Input.is_action_pressed(&"move_left")
			or Input.is_action_pressed(&"move_right")
		)

	if is_moving and not Input.is_action_pressed(&"sprint"):
		_movement_hold_time += delta
		if _movement_hold_time >= SPRINT_HINT_HOLD_DURATION:
			complete_step(&"sprinting")
	else:
		_movement_hold_time = 0.0


func _check_hunger() -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_player.hunger):
		return
	if _player.hunger.value <= LOW_HUNGER_THRESHOLD:
		complete_step(&"low_hunger")


func _on_node_added(node: Node) -> void:
	if node.is_in_group(&"player"):
		_connect_player.call_deferred(node)


func _connect_player(player: Player) -> void:
	if not is_instance_valid(player):
		return
	_player = player

	for interactor in player.interactors:
		if is_instance_valid(interactor) and not interactor.interacted_with.is_connected(_on_interacted_with):
			interactor.interacted_with.connect(_on_interacted_with)

	if is_instance_valid(player.boat_menu) and not player.boat_menu.opened.is_connected(_on_boat_menu_opened):
		player.boat_menu.opened.connect(_on_boat_menu_opened)


func _on_player_boat_docked() -> void:
	if has_completed(&"item_collecting") or has_completed(&"harvesting"):
		return

	await get_tree().create_timer(WELCOME_DELAY).timeout
	if is_instance_valid(_player) and not get_tree().paused:
		complete_step(&"welcome_goal")


func _on_interacted_with(interactable: Interactable3D) -> void:
	if interactable is ItemPickup3D:
		complete_step(&"item_collecting")


func _on_resource_harvested(payload: Dictionary) -> void:
	var source: Node = payload.get("source")
	if not is_instance_valid(_player) or source != _player:
		return

	complete_step(&"harvesting")
	complete_step(&"crafting_intro")

	var item: Item = payload.get("item")
	if is_instance_valid(item) and item.name == COPPER_ITEM_NAME:
		complete_step(&"copper_collected")


func _on_resource_resisted(payload: Dictionary) -> void:
	var source: Node = payload.get("source")
	if not is_instance_valid(_player) or source != _player:
		return

	var step_id: StringName = WEAK_TOOL_STEPS.get(payload.get("type", &""), &"")
	if not step_id.is_empty():
		complete_step(step_id)


func _on_boat_menu_opened() -> void:
	complete_step(&"boat_menu_opened")


func _on_item_crafted(item: Item) -> void:
	if item is HarvestingTool:
		complete_step(&"first_weapon_crafted")


func _on_player_survived_hurt(_hp_percent: float) -> void:
	complete_step(&"first_hit_taken")
