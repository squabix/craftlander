class_name Cannonball
extends HitProjectile3D

static var in_flight := 0
static var all: Array[Cannonball] = []

@export var blast_scene: PackedScene

var telegraph: PlanarTelegraph3D

var _exploded := false


static func clear_all() -> void:
	for ball in all:
		if not is_instance_valid(ball):
			continue
		ball.queue_free()


func _ready() -> void:
	super()
	all.append(self)
	in_flight += 1
	tree_exiting.connect(_on_tree_exiting)


func hit(area: Area3D) -> bool:
	if not area.get_parent() is Player:
		return false
	return super(area)


func _on_body_entered(body: Node3D) -> void:
	explode()
	super(body)


func _on_hit_node() -> void:
	explode()
	super()


func explode() -> void:
	if _exploded:
		return
	_exploded = true
	
	if is_instance_valid(telegraph):
		telegraph.activate()
	
	add_blast()


func add_blast() -> void:
	if blast_scene == null:
		return
	var blast := blast_scene.instantiate() as CannonBlast
	blast.hit_nodes = hit_nodes.duplicate()
	Spawner3D.root.add_child(blast)
	blast.global_position = global_position
	blast.damage = damage


func _on_tree_exiting() -> void:
	in_flight -= 1
	if not _exploded and is_instance_valid(telegraph):
		telegraph.queue_free()
