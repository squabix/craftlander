extends AnimationTree
class_name ItemAnimationTree

@export var item_animations: Array[ItemAnimations] = []
@export var do_interupt := true

@export_group("Defaults")
@export var default_start_anim := ""
@export var default_continue_anim := ""
@export var default_end_anim := ""

var item: Item
var start_anim := ""
var continue_anim := ""
var end_anim := ""

func _ready() -> void:
	default()
	get_player().animation_finished.connect(update)

func update(finished_anim: String) -> void:
	if not do_interupt:
		return
	
	match finished_anim:
		start_anim:
			if continue_anim.is_empty():
				active = true
		continue_anim:
			if end_anim.is_empty():
				active = true
		end_anim:
			active = true

func default() -> void:
	start_anim = default_start_anim
	continue_anim = default_continue_anim
	end_anim = default_end_anim

func update_item(new_item: Item) -> void:
	if item != null:
		
		# Disconnect old item signals
		item.started_use.disconnect(play_start)
		item.continued_use.disconnect(play_continue)
		item.ended_use.disconnect(play_end)
		item = null
	
	# Find new item animations or default if cannot
	var key: Item = null
	var anims: ItemAnimations = null
	for item_anims in item_animations:
		key = new_item.find_in_array(item_anims.items)
		if key != null:
			anims = item_anims
			break

	if key == null:
		default()
		return
	
	item = new_item
	
	# Set animation names
	start_anim = anims.start_anim if has_animation(anims.start_anim) else ""
	continue_anim = anims.continue_anim if has_animation(anims.continue_anim) else ""
	end_anim = anims.end_anim if has_animation(anims.end_anim) else ""
	
	# Connect use signals to animation playing functions
	item.started_use.connect(play_start)
	item.continued_use.connect(play_continue)
	item.ended_use.connect(play_end)

func get_player() -> AnimationPlayer:
	return get_node(anim_player)

func play_start() -> void:
	deactivate()
	get_player().play(start_anim)

func play_continue() -> void:
	if get_player().current_animation == start_anim:
		return
	
	deactivate()
	get_player().play(continue_anim)

func deactivate() -> void:
	if do_interupt:
		active = false

func play_end() -> void:
	deactivate()
	get_player().play(end_anim)
