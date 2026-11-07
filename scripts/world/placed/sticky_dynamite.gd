class_name StickyDynamite
extends Node2D
## A stick of dynamite stuck to a Buddy part or a wall. When the fuse runs out it
## explodes, and always takes the limb it was stuck to with it.

const FUSE := 2.5
const BLAST := [300.0, 3200.0, 70.0, 0.45]

var sandbox: Node
## The part it's stuck to, or null for a wall.
var target: BuddyPart
var local_offset := Vector2.ZERO
var fuse := FUSE
var _done := false


func setup(owner_sandbox: Node, at: Vector2, stuck_to: BuddyPart) -> void:
	sandbox = owner_sandbox
	name = "StickyDynamite"
	target = stuck_to
	global_position = at
	if target != null:
		local_offset = target.to_local(at)
	z_index = 8
	add_to_group(&"debris")
	add_to_group(&"explosive")


func prime(seconds: float) -> void:
	fuse = minf(fuse, seconds)


func detonate() -> void:
	if _done:
		return
	_done = true
	var limb := &""
	if is_instance_valid(target) and not target.detached:
		limb = target.part_name
	sandbox.explode(global_position, BLAST[0], BLAST[1], BLAST[2], BLAST[3], &"dynamite", limb)
	queue_free()


func _physics_process(delta: float) -> void:
	if is_instance_valid(target):
		global_position = target.to_global(local_offset)
		rotation = target.rotation
	fuse -= delta
	if fuse <= 0.0:
		detonate()
	queue_redraw()


func _draw() -> void:
	var outline := Color("1e1426")
	draw_rect(Rect2(-12, -30, 24, 60), outline)
	draw_rect(Rect2(-8, -26, 16, 52), Color("d23b3b"))
	draw_line(Vector2(-8, -10), Vector2(8, -10), Color("f2e3c6"), 3.0)
	draw_line(Vector2(-8, 10), Vector2(8, 10), Color("f2e3c6"), 3.0)
	var burnt := 1.0 - clampf(fuse / FUSE, 0.0, 1.0)
	var tip := Vector2(6, -30 - 18 * (1.0 - burnt))
	draw_line(Vector2(0, -30), tip, Color("2b2b2b"), 3.0)
	var flicker := 4.0 + randf() * 4.0
	draw_circle(tip, flicker, Color("ffd23f"))
	draw_circle(tip, flicker * 0.5, Color("ffffff"))
