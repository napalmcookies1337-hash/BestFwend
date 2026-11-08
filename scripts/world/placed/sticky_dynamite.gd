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
	var burnt := 1.0 - clampf(fuse / FUSE, 0.0, 1.0)
	ToolArt.dynamite_stick(self, Transform2D.IDENTITY, 4.0, Time.get_ticks_msec() / 1000.0, burnt)
