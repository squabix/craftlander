class_name TreasureChest
extends Node3D

signal opened

@export var key_condition: InteractableItemCondition

@export_group("Components")
@export var interactable: Interactable3D
@export var anim_player: AnimationPlayer
@export var state_machine: StateMachine
@export var captain_spawner: Spawner3D


func _ready() -> void:
	interactable.interacted_with.connect(_on_interacted_with)
	interactable.condition_failed.connect(_on_condition_failed)
	EventBus.subscribe(&"captain_defeated", _on_captain_defeated, tree_exiting)
	_apply_saved_state.call_deferred()


func play_locked() -> void:
	_release_meshes()
	anim_player.play(&"locked")


func open() -> void:
	_release_meshes()
	anim_player.play(&"open")
	interactable.disable()
	EventBus.trigger("treasure_chest_opened")
	opened.emit()


func _release_meshes() -> void:
	for mesh: MeshInstance3D in Util.find_children_of_class(self, &"MeshInstance3D"):
		if not MeshInstanceAggregator3D.aggregated_mesh_instances.has(mesh):
			continue
		MeshInstanceAggregator3D.disassociate_mesh_instance(mesh)


func _apply_saved_state() -> void:
	var save := Main.loaded_save as GameSave
	if save == null:
		return
	
	if save.is_tagged(GameSave.TAG_GAME_BEATEN):
		state_machine.enter_state(&"Opened")
		anim_player.play(&"open")
		anim_player.advance(anim_player.current_animation_length)
		interactable.disable()
		return
	
	if save.is_tagged(GameSave.TAG_CAPTAIN_DEFEATED):
		(state_machine.get_state(&"Unlockable") as ChestUnlockableState).key_required = false
		state_machine.enter_state(&"Unlockable")


func _on_interacted_with(source: Node) -> void:
	var player := source as Player
	if player == null:
		return
	
	var state := state_machine.get_state(state_machine.current) as ChestState
	if not is_instance_valid(state):
		return
	
	state.interact(player)


func _on_condition_failed(_condition: InteractableCondition, source: Node) -> void:
	if source is Player:
		play_locked()


func _on_captain_defeated() -> void:
	state_machine.enter_state(&"Unlockable")
