class_name BuddyPart
extends RigidBody2D
## One rigid piece of the Buddy. Reports hard contacts, and keeps the springy
## squash-and-stretch state the view draws with. Squash is visual only.
##
## A severed limb stays a BuddyPart but is `detached`: it becomes ordinary debris,
## collides with the Buddy, and draws itself.

signal impacted(part: BuddyPart, delta_v: float, normal: Vector2, at: Vector2, collider: Object)

enum Kind { CIRCLE, CAPSULE }
enum Mark { BRUISE, BLOOD, SOOT }

const BOUNCE := 0.15
const FRICTION := 0.8
## Contacts gentler than this (in px/s of velocity change) don't squash.
const SQUASH_MIN_DV := 140.0
const SQUASH_PER_DV := 1.0 / 2400.0
const MAX_SQUASH := 0.4
const JIGGLE_FREQUENCY := 5.5
const JIGGLE_DAMPING := 0.2
const MAX_MARKS := 12

var part_name: StringName
var kind := Kind.CIRCLE
var radius := 10.0
## Capsule height including both caps.
var length := 0.0
## Which part the Hand prefers when several overlap the cursor.
var pick_priority := 0
## Compression along squash_axis: positive squashes, negative stretches.
var squash := 0.0
var squash_velocity := 0.0
## World angle of the last impact's normal.
var squash_axis := 0.0
## Marks on the skin until respawn: [local position, radius, Mark].
var marks: Array = []
## Severed from the Buddy.
var detached := false
## Where it was cut, in local space, for the bloody end.
var cut_at := Vector2.ZERO
var skin_color := Color("ffa646")
var _velocity_before_step := Vector2.ZERO


## Leaves a mark near `local` on this part's skin, sized by the damage.
func add_mark(local: Vector2, mark: Mark, damage: float) -> void:
	var mark_radius := clampf(4.0 + damage * 0.6, 5.0, radius * 0.45)
	var reach := maxf(radius - mark_radius - 2.0, 0.0)
	var spot := local
	if kind == Kind.CIRCLE:
		spot = local.limit_length(reach)
	else:
		var half := maxf(length / 2.0 - radius, 0.0)
		spot = Vector2(clampf(local.x, -reach, reach), clampf(local.y, -half - reach * 0.5, half + reach * 0.5))
	marks.append([spot, mark_radius, mark])
	if marks.size() > MAX_MARKS:
		marks.pop_front()


func setup(id: StringName, part_kind: Kind, part_radius: float, part_length: float, part_mass: float, priority: int) -> void:
	part_name = id
	name = String(id)
	kind = part_kind
	radius = part_radius
	length = part_length
	mass = part_mass
	pick_priority = priority
	var collider := CollisionShape2D.new()
	if kind == Kind.CIRCLE:
		var circle := CircleShape2D.new()
		circle.radius = radius
		collider.shape = circle
	else:
		var capsule := CapsuleShape2D.new()
		capsule.radius = radius
		capsule.height = length
		collider.shape = capsule
	add_child(collider)
	collision_layer = Layers.BUDDY
	collision_mask = Layers.WALLS | Layers.OBJECTS
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	can_sleep = false
	var surface := PhysicsMaterial.new()
	surface.bounce = BOUNCE
	surface.friction = FRICTION
	physics_material_override = surface
	add_to_group(&"grabbable")


## Turns this part into a loose, bloody piece of debris.
func detach(color: Color, cut_local: Vector2) -> void:
	detached = true
	skin_color = color
	cut_at = cut_local
	collision_layer = Layers.OBJECTS
	collision_mask = Layers.WALLS | Layers.BUDDY | Layers.OBJECTS
	add_to_group(&"debris")
	z_index = 1
	queue_redraw()


func kick_squash(normal: Vector2, delta_v: float) -> void:
	var amount := minf(delta_v * SQUASH_PER_DV, MAX_SQUASH)
	if amount <= squash:
		return
	squash = amount
	squash_velocity = 0.0
	squash_axis = normal.angle()


func _physics_process(delta: float) -> void:
	var omega := TAU * JIGGLE_FREQUENCY
	squash_velocity += (-omega * omega * squash - 2.0 * JIGGLE_DAMPING * omega * squash_velocity) * delta
	squash += squash_velocity * delta
	# Runs after the Buddy and the Hand have changed velocities, just before the step.
	_velocity_before_step = linear_velocity


## Impact strength is the velocity the collision took away along the contact normal.
## Godot's reported contact impulses are unreliable in 2D, so this measures the result.
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var count := state.get_contact_count()
	if count == 0 or detached:
		return
	var before := _velocity_before_step
	var expected := before + state.total_gravity * state.step
	var change := state.linear_velocity - expected
	var strongest := 0.0
	var normal := Vector2.ZERO
	var at := Vector2.ZERO
	var collider: Object = null
	for index in count:
		# A collision only ever pushes against how fast the two surfaces were closing.
		# A change that doesn't came from a joint yank (say, legs lifted off the floor).
		var relative := before - state.get_contact_collider_velocity_at_position(index)
		if change.dot(relative) >= 0.0:
			continue
		var contact_normal := state.get_contact_local_normal(index)
		var approach := absf(relative.dot(contact_normal))
		var delta_v := minf(absf(change.dot(contact_normal)), approach * (1.0 + BOUNCE * 3.0) + 60.0)
		# A heavy object landing on a part the rest of the body holds up barely
		# changes that part's speed, but it should still crush. Count the closing
		# speed, weighted by how much heavier the object is.
		var other := state.get_contact_collider_object(index) as RigidBody2D
		if other != null:
			delta_v = maxf(delta_v, approach * other.mass / (other.mass + mass))
		if delta_v > strongest:
			strongest = delta_v
			normal = contact_normal
			at = state.get_contact_local_position(index)
			collider = state.get_contact_collider_object(index)
	if strongest >= SQUASH_MIN_DV:
		kick_squash(normal, strongest)
		impacted.emit(self, strongest, normal, at, collider)


func _draw() -> void:
	if not detached:
		return
	var outline := BuddyView.OUTLINE_COLOR
	var points := BuddyView.capsule_points(radius + BuddyView.OUTLINE, length + BuddyView.OUTLINE * 2.0)
	draw_colored_polygon(points, outline)
	var fill := skin_color.darkened(0.18) if String(part_name).begins_with("leg") else skin_color
	draw_colored_polygon(BuddyView.capsule_points(radius, length), fill)
	for mark: Array in marks:
		draw_circle(mark[0], mark[1], BuddyView.mark_color(mark[2]))
	draw_circle(cut_at, radius * 0.85, BuddyView.BLOOD)
	draw_circle(cut_at, radius * 0.4, Color("f3d9c4"))
