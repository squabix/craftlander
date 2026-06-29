extends Resource
class_name ItemAnimations

@export var items: Array[Item]
@export var start_anim := ""
@export var continue_anim := ""
@export var end_anim := ""

func _to_string() -> String:
	if start_anim.is_empty() and continue_anim.is_empty() and end_anim.is_empty():
		return "ItemAnimations (empty)"
	
	var s := "ItemAnimations ("
	if not start_anim.is_empty():
		s += start_anim
	if not continue_anim.is_empty():
		s += " → %s" %continue_anim
	if not end_anim.is_empty():
		s += " → %s" %end_anim
	s += ")"
	
	return s
