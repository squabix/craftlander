class_name PlanarTelegraphVfx
extends Object

const WEDGE_SCRIPT := preload("res://common3d/telegraphs/wedge_telegraph3d.gd")
const RECTANGLE_SCRIPT := preload("res://common3d/telegraphs/rectangle_telegraph3d.gd")
const DISC_SCRIPT := preload("res://common3d/telegraphs/disc_telegraph3d.gd")

const GROUND_MASK := 64


static func wedge(parent: Node, origin: Vector3, yaw: float, radius: float, arc: float, color: Color, duration: float) -> WedgeTelegraph3D:
	var telegraph := WEDGE_SCRIPT.new() as WedgeTelegraph3D
	telegraph.radius = radius
	telegraph.arc_degrees = rad_to_deg(arc)
	return _spawn(telegraph, parent, origin, yaw, color, duration) as WedgeTelegraph3D


static func rectangle(parent: Node, origin: Vector3, yaw: float, size: Vector2, color: Color, duration: float) -> RectangleTelegraph3D:
	var telegraph := RECTANGLE_SCRIPT.new() as RectangleTelegraph3D
	telegraph.size = size
	return _spawn(telegraph, parent, origin, yaw, color, duration) as RectangleTelegraph3D


static func disc(parent: Node, center: Vector3, radius: float, color: Color, duration: float) -> DiscTelegraph3D:
	var telegraph := DISC_SCRIPT.new() as DiscTelegraph3D
	telegraph.radius = radius
	return _spawn(telegraph, parent, center, 0.0, color, duration) as DiscTelegraph3D


static func _spawn(telegraph: PlanarTelegraph3D, parent: Node, origin: Vector3, yaw: float, color: Color, duration: float) -> PlanarTelegraph3D:
	telegraph.color_base = color
	telegraph.fill_duration = duration
	telegraph.normal_ground_mask = GROUND_MASK
	parent.add_child(telegraph)
	telegraph.global_position = origin
	telegraph.rotation.y = yaw
	telegraph.yaw = yaw
	return telegraph
