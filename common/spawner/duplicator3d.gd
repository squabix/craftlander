class_name Duplicator3D
extends Spawner3D

@export var templates: Array[Node3D] = []
@export var templates_persist := false

var packed_templates: Array[PackedScene] = []


func _ready() -> void:
	super()
	pack_templates()


func pack_templates() -> void:
	packed_templates.clear()

	for template in templates:
		if not is_instance_valid(template):
			continue
		
		var packed_scene: PackedScene
		var result: Error
		
		if template.scene_file_path.is_empty():
			packed_scene = PackedScene.new()
			result = packed_scene.pack(template)
		else:
			packed_scene = load(template.scene_file_path)
			result = OK

		if result == OK:
			packed_templates.append(packed_scene)
		else:
			Util.node_error("%s failed to pack template: %s", self, template)

		if not templates_persist:
			Util.safe_free(template)


func create_instance() -> Node3D:
	if packed_templates.is_empty():
		pack_templates()
		if packed_templates.is_empty():
			push_warning("%s has no valid packed templates to duplicate", name)
			return super()

	var chosen_packed_scene: PackedScene = packed_templates.pick_random()
	return chosen_packed_scene.instantiate() as Node3D
