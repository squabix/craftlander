extends Resource
class_name IslandProp

@export var scene: PackedScene
@export var radius := 1.0
@export var min_height := 0.0
@export var max_height := 1000.0
@export var min_scale := 1.0
@export var max_scale := 1.0
@export_range(0.0, 1.0) var normal_conformity := 1.0
