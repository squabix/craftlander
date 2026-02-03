extends AnimationPlayer
class_name ItemAnimationPlayer

@export var item_animations: Dictionary[Item, ItemAnimations] = {}

@export_group("Defaults")
@export var default_start_anim := ""
@export var default_continue_anim := ""
@export var default_end_anim := ""

@export_group("Tree")
@export var anim_tree: AnimationTree
@export var do_interupt_tree := true

var item: Item
var start_anim := ""
var continue_anim := ""
var end_anim := ""

func _ready() -> void:
	default()
	animation_finished.connect(update_tree)

func update_tree(finished_anim: String) -> void:
	if not (do_interupt_tree and is_instance_valid(anim_tree)):
		return
	
	match finished_anim:
		start_anim:
			if continue_anim.is_empty():
				anim_tree.active = true
		continue_anim:
			if end_anim.is_empty():
				anim_tree.active = true
		end_anim:
			anim_tree.active = true

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
	var key := new_item.find_in_array(item_animations.keys())
	if key == null or item_animations[key] == null:
		default()
		return
	
	item = new_item
	
	# Set animation names
	var anims: ItemAnimations = item_animations[key]
	start_anim = anims.start_anim if has_animation(anims.start_anim) else ""
	continue_anim = anims.continue_anim if has_animation(anims.continue_anim) else ""
	end_anim = anims.end_anim if has_animation(anims.end_anim) else ""
	
	# Connect use signals to animation playing functions
	item.started_use.connect(play_start)
	item.continued_use.connect(play_continue)
	item.ended_use.connect(play_end)

func play_start() -> void:
	deactivate_tree()
	play(start_anim)

func play_continue() -> void:
	if current_animation == start_anim:
		return
	
	deactivate_tree()
	play(continue_anim)

func deactivate_tree() -> void:
	if do_interupt_tree and is_instance_valid(anim_tree):
		anim_tree.active = false

func play_end() -> void:
	deactivate_tree()
	play(end_anim)
