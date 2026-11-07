class_name Blood
extends Node2D
## Blood spray. Listens for damaging hits, splats the impact point, and throws
## droplets that fly under gravity and stain wherever they land. Gore is always on.

const MIN_DAMAGE := 2.0
const DROPS_PER_DAMAGE := 1.4
const MAX_DROPS_PER_HIT := 46
const MAX_LIVE_DROPS := 500
const DROP_SPEED := Vector2(220.0, 950.0)
const COLOR := Color("a3121f")
const OUTLINE := Color("4d0710")

var decals: DecalLayer
var bounds := Rect2(Vector2.ZERO, Vector2(1920, 880))
## [position, velocity, radius] per flying drop.
var drops: Array = []
## [node, local point, seconds left] for stumps and severed ends that keep bleeding.
var wounds: Array = []
const BLEED_RATE := 30.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "Blood"
	z_index = 5
	_rng.randomize()
	Events.buddy_hit.connect(_on_buddy_hit)


func spray(at: Vector2, damage: float, carried: Vector2 = Vector2.ZERO) -> void:
	var splat_radius := clampf(6.0 + damage * 0.9, 8.0, 40.0)
	# Hits on a wall happen right at its edge; pull the stain in so it all shows.
	decals.splat(_inside(at, splat_radius * 0.6), splat_radius)
	var count := clampi(int(damage * DROPS_PER_DAMAGE), 4, MAX_DROPS_PER_HIT)
	var up := -_gravity().normalized() if _gravity().length() > 1.0 else Vector2.UP
	for _index in count:
		if drops.size() >= MAX_LIVE_DROPS:
			drops.pop_front()
		var direction := up.rotated(_rng.randf_range(-1.6, 1.6))
		var velocity := direction * _rng.randf_range(DROP_SPEED.x, DROP_SPEED.y) * clampf(damage / 20.0, 0.5, 1.6)
		drops.append([at, velocity + carried * 0.25, _rng.randf_range(2.0, 6.0)])


## Keeps dripping from `local` on `node` for `seconds`.
func bleed(node: Node2D, local: Vector2, seconds: float) -> void:
	wounds.append([node, local, seconds])


func clear() -> void:
	drops.clear()
	wounds.clear()
	queue_redraw()


func _physics_process(delta: float) -> void:
	for index in range(wounds.size() - 1, -1, -1):
		var wound: Array = wounds[index]
		wound[2] -= delta
		if wound[2] <= 0.0 or not is_instance_valid(wound[0]):
			wounds.remove_at(index)
			continue
		if _rng.randf() < BLEED_RATE * delta and drops.size() < MAX_LIVE_DROPS:
			var source: Node2D = wound[0]
			var at := source.to_global(wound[1])
			var velocity := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(60.0, 260.0)
			if source is RigidBody2D:
				velocity += (source as RigidBody2D).linear_velocity
			drops.append([at, velocity, _rng.randf_range(2.0, 4.5)])
	if drops.is_empty():
		return
	var g := _gravity()
	var landed: Array[int] = []
	for index in drops.size():
		var drop: Array = drops[index]
		var velocity: Vector2 = drop[1] + g * delta
		var at: Vector2 = drop[0] + velocity * delta
		drop[0] = at
		drop[1] = velocity
		if not bounds.has_point(at) or (g.length() < 1.0 and velocity.length() < 40.0):
			decals.drop(_inside(at, drop[2]), drop[2] * 1.6)
			landed.append(index)
	for offset in landed.size():
		drops.remove_at(landed[landed.size() - 1 - offset])
	queue_redraw()


func _draw() -> void:
	for drop: Array in drops:
		var stretch: Vector2 = drop[1] * 0.012
		draw_line(drop[0] - stretch, drop[0], OUTLINE, drop[2] * 2.0 + 2.0, true)
		draw_line(drop[0] - stretch, drop[0], COLOR, drop[2] * 2.0, true)


func _on_buddy_hit(info: Dictionary) -> void:
	var damage: float = info.get("damage", 0.0)
	if damage < MIN_DAMAGE or not info.has("position") or not info.get("bleed", true):
		return
	spray(info["position"], damage)


func _inside(at: Vector2, margin: float) -> Vector2:
	var area := bounds.grow(-margin)
	return at.clamp(area.position, area.end)


func _gravity() -> Vector2:
	var space := get_world_2d().space
	var direction: Vector2 = PhysicsServer2D.area_get_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR)
	return direction * float(PhysicsServer2D.area_get_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY))
