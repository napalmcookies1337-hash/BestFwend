extends ToolBehavior
## Chainsaw: hold it against anything. No swing needed: it chews through
## whatever touches the blade, and a limb held to it for a moment comes off.
## params: "dps", "reach", "sever_after".

const TICK := 0.1

var _tick := 0.0
var _contact: Dictionary = {}
var _phase := 0.0
var _query := PhysicsShapeQueryParameters2D.new()


func press(_at: Vector2) -> void:
	_contact.clear()
	var circle := CircleShape2D.new()
	circle.radius = float(param("reach", 40.0))
	_query.shape = circle
	_query.collision_mask = Layers.BUDDY | Layers.OBJECTS
	Sfx.play(&"chainsaw", -4.0)


func hold(at: Vector2, delta: float) -> void:
	_phase += delta
	_tick += delta
	if _tick < TICK:
		return
	_tick = 0.0
	Sfx.play(&"chainsaw", -8.0, randf_range(0.95, 1.1), 0.0)
	_query.transform = Transform2D(0.0, at)
	var touching: Dictionary = {}
	for hit in sandbox.get_world_2d().direct_space_state.intersect_shape(_query, 12):
		var body := hit["collider"] as RigidBody2D
		if body == null:
			continue
		body.linear_velocity += Vector2(randf_range(-160, 160), randf_range(-220, 40))
		if not (body is BuddyPart) or (body as BuddyPart).detached:
			continue
		var part := body as BuddyPart
		var victim := owner_of(part)
		touching[part] = true
		_contact[part] = float(_contact.get(part, 0.0)) + TICK
		if Buddy.LIMBS.has(part.part_name) and _contact[part] >= float(param("sever_after", 0.6)) / power():
			victim.sever(part.part_name, Vector2(randf_range(-400, 400), -500), &"chainsaw")
			Sfx.play(&"slice", 0.0)
			sandbox.add_shake(12.0)
			continue
		victim.take_hit({"part": part.part_name, "force": 900.0, "damage": float(param("dps", 70.0)) * TICK * power(),
				"source": &"chainsaw", "position": at})
		sandbox.blood.spray(at, 6.0)
		sandbox.add_shake(4.0)
	for part: Variant in _contact.keys():
		if not touching.has(part):
			_contact.erase(part)


func release(_at: Vector2) -> void:
	_contact.clear()


func draw_cursor(canvas: CanvasItem, at: Vector2) -> void:
	var revving := sandbox.tools.active == self
	var jitter := Vector2(randf_range(-3, 3), randf_range(-3, 3)) if revving else Vector2.ZERO
	ToolArt.chainsaw(canvas, Transform2D(-0.5, Vector2.ONE * 1.4, 0.0, at + jitter + Vector2(30, 40)), 3.5)
