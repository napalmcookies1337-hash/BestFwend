extends Node
## The background music: a bouncy cartoon loop (plucky bass, xylophone tune,
## oom-pah chord stabs, light drums) composed and synthesized in code at startup,
## on a worker thread so the game doesn't wait for it. Plays on the Music bus.

const RATE := 22050
const BPM := 120.0
const STEP := 60.0 / BPM / 2.0
## Chords per bar: root MIDI note and whether it's minor.
const CHORDS := [[48, false], [45, true], [41, false], [43, false], [48, false], [45, true], [50, true], [43, false]]
## The tune, one MIDI note per eighth note (-1 rests), eight bars.
const MELODY := [
	76, -1, 79, -1, 81, 79, 76, -1,
	72, -1, 76, -1, 74, 72, 69, -1,
	77, -1, 81, -1, 84, 81, 77, 76,
	74, -1, 79, -1, 77, 76, 74, -1,
	76, 76, 79, -1, 84, -1, 79, -1,
	81, -1, 79, 76, 72, -1, 76, -1,
	77, -1, 74, -1, 77, 81, 79, 77,
	79, -1, 74, -1, 71, -1, 67, -1,
]
const LEVEL_DB := -7.0

var player: AudioStreamPlayer
var stream: AudioStreamWAV
var _task := -1


func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.bus = &"Music"
	player.volume_db = LEVEL_DB
	add_child(player)
	if DisplayServer.get_name() == "headless":
		return
	_task = WorkerThreadPool.add_task(_build_in_background)


func _exit_tree() -> void:
	if _task != -1:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


func _build_in_background() -> void:
	var built := build()
	_on_built.call_deferred(built)


func _on_built(built: AudioStreamWAV) -> void:
	if _task != -1:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
	stream = built
	player.stream = stream
	player.play()


## Composes and renders the whole loop. Pure: safe to call from any thread.
static func build() -> AudioStreamWAV:
	var steps := MELODY.size()
	var length := int(steps * STEP * RATE)
	var mix := PackedFloat32Array()
	mix.resize(length)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for step in steps:
		var at := int(step * STEP * RATE)
		var bar := step / 8
		var beat_step := step % 8
		var chord: Array = CHORDS[bar]
		var root: int = chord[0]
		var third: int = root + (3 if chord[1] else 4)
		# Bass: root and fifth on the beats, a pickup on the last eighth.
		if beat_step % 2 == 0:
			var bass_note: int = root - 12 + (7 if beat_step % 4 == 2 else 0)
			_add(mix, at, _bass(_hz(bass_note)), 0.55)
		elif beat_step == 7:
			_add(mix, at, _bass(_hz(root - 12 + 12)), 0.35)
		# Oom-pah: chord stabs on beats 2 and 4.
		if beat_step == 2 or beat_step == 6:
			for note: int in [root + 12, third + 12, root + 19]:
				_add(mix, at, _stab(_hz(note)), 0.12)
		# Tune.
		var lead: int = MELODY[step]
		if lead >= 0:
			_add(mix, at, _xylo(_hz(lead)), 0.42)
		# Drums: kick on 1 and 3, clap on 2 and 4, a soft hat on every eighth.
		if beat_step == 0 or beat_step == 4:
			_add(mix, at, _kick(), 0.6)
		if beat_step == 2 or beat_step == 6:
			_add(mix, at, _clap(rng), 0.22)
		_add(mix, at, _hat(rng), 0.06 if beat_step % 2 == 0 else 0.1)
	var peak := 0.0001
	for value in mix:
		peak = maxf(peak, absf(value))
	var data := PackedByteArray()
	data.resize(length * 2)
	for index in length:
		data.encode_s16(index * 2, int(clampf(mix[index] / peak * 0.9, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = length
	return wav


static func _hz(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


## Adds `sound` into `mix` at `at`, wrapping round the end so the loop is seamless.
static func _add(mix: PackedFloat32Array, at: int, sound: PackedFloat32Array, gain: float) -> void:
	var size := mix.size()
	for index in sound.size():
		var spot := (at + index) % size
		mix[spot] += sound[index] * gain


static func _xylo(frequency: float) -> PackedFloat32Array:
	var count := int(0.45 * RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	for index in count:
		var t := float(index) / RATE
		var phase := TAU * frequency * t
		var value := sin(phase) + sin(phase * 4.0) * 0.35 * exp(-t * 30.0) + sin(phase * 9.8) * 0.12 * exp(-t * 70.0)
		out[index] = value * exp(-t * 8.0) * minf(t / 0.002, 1.0)
	return out


static func _bass(frequency: float) -> PackedFloat32Array:
	var count := int(0.3 * RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase := 0.0
	for index in count:
		var t := float(index) / RATE
		# A little pitch drop at the start makes it "boing".
		phase += TAU * frequency * (1.0 + 0.06 * exp(-t * 40.0)) / RATE
		var value := sin(phase) + sin(phase * 2.0) * 0.45 + sin(phase * 3.0) * 0.2
		out[index] = value * exp(-t * 9.0) * minf(t / 0.004, 1.0)
	return out


static func _stab(frequency: float) -> PackedFloat32Array:
	var count := int(0.14 * RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	for index in count:
		var t := float(index) / RATE
		var phase := fmod(frequency * t, 1.0)
		# Triangle wave: soft and reedy.
		var value := 4.0 * absf(phase - 0.5) - 1.0
		out[index] = value * exp(-t * 20.0) * minf(t / 0.003, 1.0)
	return out


static func _kick() -> PackedFloat32Array:
	var count := int(0.18 * RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase := 0.0
	for index in count:
		var t := float(index) / RATE
		phase += TAU * lerpf(130.0, 45.0, minf(t / 0.12, 1.0)) / RATE
		out[index] = sin(phase) * exp(-t * 22.0)
	return out


static func _clap(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var count := int(0.1 * RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var smooth := 0.0
	for index in count:
		var t := float(index) / RATE
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), 0.45)
		out[index] = smooth * 2.0 * exp(-t * 38.0)
	return out


static func _hat(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var count := int(0.04 * RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var last := 0.0
	for index in count:
		var t := float(index) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		out[index] = (noise - last) * 0.5 * exp(-t * 90.0)
		last = noise
	return out
