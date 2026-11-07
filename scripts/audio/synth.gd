class_name Synth
extends RefCounted
## Builds sounds from math: voiced tones for the Buddy's babble and yelps, and
## filtered noise for impacts. Everything comes out as an AudioStreamWAV.

const RATE := 22050


## A pitched voice that glides from f_start to f_end (Hz). `harmonics` are the
## strengths of overtones 1, 2, 3...: they set the vowel colour.
static func voice(f_start: float, f_end: float, seconds: float, harmonics: Array,
		vibrato_hz := 0.0, vibrato_depth := 0.0, breath := 0.0, attack := 0.01) -> PackedFloat32Array:
	var count := int(seconds * RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(f_start * 1000.0 + seconds * 100.0)
	var total := 0.0
	for weight: float in harmonics:
		total += absf(weight)
	for index in count:
		var t := float(index) / RATE
		var progress := t / seconds
		var frequency := lerpf(f_start, f_end, progress)
		frequency *= 1.0 + sin(TAU * vibrato_hz * t) * vibrato_depth
		phase += TAU * frequency / RATE
		var value := 0.0
		for harmonic in harmonics.size():
			value += sin(phase * (harmonic + 1)) * float(harmonics[harmonic])
		value /= total
		value += rng.randf_range(-1.0, 1.0) * breath
		samples[index] = value * _envelope(t, seconds, attack, seconds * 0.35)
	return samples


## Noise through a simple low-pass, with an optional low thump under it.
static func hit(seconds: float, brightness: float, thump_hz := 0.0, thump_mix := 0.0, seed_value := 1) -> PackedFloat32Array:
	var count := int(seconds * RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var smooth := 0.0
	var phase := 0.0
	for index in count:
		var t := float(index) / RATE
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), brightness)
		phase += TAU * thump_hz * (1.0 - t / seconds * 0.5) / RATE
		var value := smooth * (1.0 - thump_mix) * 2.0 + sin(phase) * thump_mix
		samples[index] = value * _envelope(t, seconds, 0.002, seconds * 0.9)
	return samples


static func concat(parts: Array) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	for part: PackedFloat32Array in parts:
		result.append_array(part)
	return result


static func silence(seconds: float) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(int(seconds * RATE))
	return result


static func to_stream(samples: PackedFloat32Array, gain := 0.8) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for index in samples.size():
		data.encode_s16(index * 2, int(clampf(samples[index] * gain, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream


## Fast attack, flat middle, smooth release, so nothing clicks.
static func _envelope(t: float, seconds: float, attack: float, release: float) -> float:
	if t < attack:
		return t / attack
	var left := seconds - t
	if left < release:
		return pow(maxf(left / release, 0.0), 1.5)
	return 1.0
