class_name GhostMeleeCoordinator
extends Node

@export var player: Node3D

@export_group("Tokens", "token")
@export var token_max_melee := 4
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var token_idle_release_time := 3.5
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var token_cooldown_time := 3.5

@export_group("Slot", "slot")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var slot_goal_margin := 1.0

@export_group("Orbit", "orbit")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var orbit_radius_min := 4.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var orbit_radius_max := 6.5
@export_custom(PROPERTY_HINT_NONE, "suffix:rad/s") var orbit_speed := 0.25

var _members: Array[Member] = []
var _clock := 0.0


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	_members.assign(_members.filter(is_member_valid))
	_clock += delta
	assign_tokens(_clock, delta)
	for member in _members:
		update_member(member, delta)


static func is_member_valid(member: Member) -> bool:
	return member != null and is_instance_valid(member.traits)


func register(traits: GhostTraits) -> void:
	var member := Member.new()
	member.traits = traits
	member.orbit_radius = randf_range(orbit_radius_min, orbit_radius_max)
	member.orbit_direction = 1.0 if randf() < 0.5 else -1.0
	_members.append(member)
	traits.allow_specials(traits.is_ranged)


func assign_tokens(now: float, delta: float) -> void:
	var melee := get_melee_members()
	update_idle_times(melee, delta)
	release_idle_tokens(melee, now)
	grant_tokens(melee, now)


func get_melee_members() -> Array[Member]:
	var melee: Array[Member] = []
	for member in _members:
		if not member.traits.is_ranged:
			melee.append(member)
	return melee


func update_idle_times(melee: Array[Member], delta: float) -> void:
	for member in melee:
		if member.has_token:
			member.idle_time = 0.0 if is_engaged(member) else member.idle_time + delta


func release_idle_tokens(melee: Array[Member], now: float) -> void:
	var waiting := melee.filter(can_take_token.bind(now)).size()
	for member in melee:
		if waiting <= 0:
			return
		if not should_release_token(member):
			return
		release_token(member, now)
		waiting -= 1


func grant_tokens(melee: Array[Member], now: float) -> void:
	var holders := melee.filter(has_token).size()
	var candidates := melee.filter(can_take_token.bind(now))
	candidates.sort_custom(is_closer_to_player)
	for member: Member in candidates:
		if holders >= token_max_melee:
			return
		give_token(member)
		holders += 1


func should_release_token(member: Member) -> bool:
	return member.has_token and member.idle_time >= token_idle_release_time


func can_take_token(member: Member, now: float) -> bool:
	return not member.has_token and now - member.released_at >= token_cooldown_time


func has_token(member: Member) -> bool:
	return member.has_token


func release_token(member: Member, now: float) -> void:
	member.has_token = false
	member.released_at = now
	member.traits.allow_specials(false)
	member.angle = get_bearing(member.traits)


func give_token(member: Member) -> void:
	member.has_token = true
	member.idle_time = 0.0
	member.traits.allow_specials(true)


func is_closer_to_player(a: Member, b: Member) -> bool:
	return distance_to_player(a) < distance_to_player(b)


func update_member(member: Member, delta: float) -> void:
	var traits := member.traits
	
	var bearing := get_bearing(traits)
	if is_nan(member.angle):
		member.angle = bearing

	var radius := 0.0
	if traits.is_ranged or member.has_token:
		member.angle = bearing
		radius = maxf(traits.get_goal_distance() - slot_goal_margin, 0.2)
	else:
		member.angle += member.orbit_direction * orbit_speed * delta
		radius = member.orbit_radius
	
	traits.guide.slot_offset = Vector3(cos(member.angle), 0.0, sin(member.angle)) * radius


func is_engaged(member: Member) -> bool:
	return member.traits.guide.get_distance_to_target() <= member.traits.get_goal_distance()


func get_bearing(traits: GhostTraits) -> float:
	var away := traits.entity.global_position - player.global_position
	return atan2(away.z, away.x)


func distance_to_player(member: Member) -> float:
	return player.global_position.distance_to(member.traits.entity.global_position)


class Member:
	var traits: GhostTraits
	var angle := NAN
	var orbit_radius := 7.0
	var orbit_direction := 1.0
	var has_token := false
	var idle_time := 0.0
	var released_at := -INF
