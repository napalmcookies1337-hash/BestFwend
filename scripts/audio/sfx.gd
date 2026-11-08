extends Node
## Plays the game's sounds on the SFX bus. Every sound is synthesized once at
## startup (see Synth), so there are no audio files to ship.

const VOICES := 14
## Vowel colours for babble syllables: overtone strengths.
const VOWELS := {
	&"a": [1.0, 0.8, 0.6, 0.3, 0.15],
	&"e": [1.0, 0.35, 0.5, 0.6, 0.3],
	&"i": [0.7, 0.2, 0.2, 0.6, 0.7, 0.4],
	&"o": [1.0, 0.7, 0.2, 0.1],
	&"u": [1.0, 0.3, 0.08],
}

var sounds: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	for index in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_players.append(player)
	_build()


## Plays a named sound. pitch_jitter varies the pitch a little each time so
## repeats don't sound identical.
func play(sound: StringName, volume_db := 0.0, pitch := 1.0, pitch_jitter := 0.06) -> void:
	var stream: AudioStream = sounds.get(sound)
	if stream == null:
		push_warning("No sound named %s" % sound)
		return
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = maxf(pitch * (1.0 + _rng.randf_range(-pitch_jitter, pitch_jitter)), 0.05)
	player.play()


## One babble syllable at the Buddy's voice pitch.
func babble(voice_pitch := 1.0) -> void:
	var vowel: StringName = VOWELS.keys()[_rng.randi() % VOWELS.size()]
	play(StringName("syllable_" + vowel), -6.0, voice_pitch, 0.14)


func _build() -> void:
	for vowel: StringName in VOWELS:
		var tone := Synth.voice(330.0, 300.0, 0.075, VOWELS[vowel], 18.0, 0.03, 0.02, 0.008)
		sounds[StringName("syllable_" + vowel)] = Synth.to_stream(tone, 0.7)
	var bright := [1.0, 0.5, 0.35, 0.2]
	sounds[&"squeak"] = Synth.to_stream(Synth.voice(700.0, 1250.0, 0.13, bright, 30.0, 0.04))
	sounds[&"yelp"] = Synth.to_stream(Synth.concat([
		Synth.voice(620.0, 980.0, 0.08, bright, 0.0, 0.0, 0.03),
		Synth.voice(980.0, 520.0, 0.2, bright, 12.0, 0.05, 0.04)]))
	sounds[&"grunt"] = Synth.to_stream(Synth.voice(210.0, 120.0, 0.24, [1.0, 0.9, 0.7, 0.5, 0.3], 9.0, 0.06, 0.12))
	sounds[&"scream"] = Synth.to_stream(Synth.voice(780.0, 600.0, 1.0, [1.0, 0.6, 0.45, 0.3, 0.2], 9.0, 0.07, 0.06), 0.6)
	sounds[&"ko"] = Synth.to_stream(Synth.voice(420.0, 110.0, 0.9, [1.0, 0.5, 0.25], 6.0, 0.12, 0.02))
	sounds[&"revive"] = Synth.to_stream(Synth.concat([
		Synth.voice(523.0, 523.0, 0.09, [1.0, 0.3]),
		Synth.voice(659.0, 659.0, 0.09, [1.0, 0.3]),
		Synth.voice(784.0, 800.0, 0.2, [1.0, 0.3], 7.0, 0.02)]), 0.5)
	sounds[&"yawn"] = Synth.to_stream(Synth.voice(320.0, 170.0, 1.0, [1.0, 0.6, 0.3], 4.0, 0.03, 0.08, 0.15), 0.6)
	sounds[&"giggle"] = Synth.to_stream(Synth.concat([
		Synth.voice(600.0, 700.0, 0.06, bright), Synth.silence(0.03),
		Synth.voice(640.0, 740.0, 0.06, bright), Synth.silence(0.03),
		Synth.voice(680.0, 780.0, 0.07, bright)]), 0.6)
	sounds[&"thud"] = Synth.to_stream(Synth.hit(0.2, 0.08, 70.0, 0.6, 3))
	sounds[&"smack"] = Synth.to_stream(Synth.hit(0.14, 0.35, 140.0, 0.3, 5))
	sounds[&"crunch"] = Synth.to_stream(Synth.hit(0.3, 0.5, 55.0, 0.45, 7))
	sounds[&"splat"] = Synth.to_stream(Synth.hit(0.22, 0.18, 0.0, 0.0, 11), 0.6)
	sounds[&"pop"] = Synth.to_stream(Synth.voice(900.0, 500.0, 0.05, [1.0]), 0.4)
	# Tools.
	sounds[&"boom"] = Synth.to_stream(Synth.hit(0.9, 0.12, 48.0, 0.5, 21), 0.95)
	sounds[&"big_boom"] = Synth.to_stream(Synth.hit(2.2, 0.06, 32.0, 0.55, 23), 1.0)
	sounds[&"bang"] = Synth.to_stream(Synth.hit(0.16, 0.7, 180.0, 0.25, 25), 0.9)
	sounds[&"zap"] = Synth.to_stream(Synth.concat([Synth.hit(0.08, 0.95, 0.0, 0.0, 27),
		Synth.voice(1400.0, 300.0, 0.35, [1.0, 0.0, 0.6, 0.0, 0.4], 60.0, 0.2, 0.4)]), 0.7)
	sounds[&"fwoosh"] = Synth.to_stream(Synth.hit(0.6, 0.15, 0.0, 0.0, 29), 0.7)
	sounds[&"freeze"] = Synth.to_stream(Synth.voice(2200.0, 3200.0, 0.45, [1.0, 0.0, 0.3], 25.0, 0.05, 0.25), 0.4)
	sounds[&"whoosh"] = Synth.to_stream(Synth.hit(0.45, 0.25, 0.0, 0.0, 31), 0.6)
	sounds[&"whistle"] = Synth.to_stream(Synth.voice(1500.0, 500.0, 1.4, [1.0, 0.1], 5.0, 0.01, 0.03, 0.05), 0.35)
	sounds[&"swish"] = Synth.to_stream(Synth.hit(0.2, 0.3, 0.0, 0.0, 33), 0.5)
	sounds[&"slice"] = Synth.to_stream(Synth.concat([Synth.voice(3000.0, 1800.0, 0.06, [1.0, 0.5], 0.0, 0.0, 0.5),
		Synth.hit(0.18, 0.2, 90.0, 0.4, 35)]), 0.75)
	sounds[&"hum"] = Synth.to_stream(Synth.voice(70.0, 55.0, 1.2, [1.0, 0.6, 0.4, 0.3], 3.0, 0.08, 0.05, 0.2), 0.7)
	sounds[&"clink"] = Synth.to_stream(Synth.voice(2600.0, 2400.0, 0.12, [1.0, 0.0, 0.4, 0.0, 0.2], 0.0, 0.0, 0.05, 0.002), 0.45)
	sounds[&"shatter"] = Synth.to_stream(Synth.concat([Synth.hit(0.12, 0.9, 0.0, 0.0, 41),
		Synth.voice(3400.0, 3100.0, 0.08, [1.0, 0.0, 0.5], 0.0, 0.0, 0.3, 0.002),
		Synth.voice(2700.0, 2500.0, 0.1, [1.0, 0.0, 0.5], 0.0, 0.0, 0.3, 0.002),
		Synth.voice(3900.0, 3600.0, 0.16, [1.0, 0.0, 0.4], 0.0, 0.0, 0.2, 0.002)]), 0.6)
	sounds[&"cha_ching"] = Synth.to_stream(Synth.concat([Synth.hit(0.05, 0.8, 0.0, 0.0, 43),
		Synth.voice(1320.0, 1320.0, 0.09, [1.0, 0.0, 0.4, 0.0, 0.2], 0.0, 0.0, 0.0, 0.003),
		Synth.voice(1760.0, 1760.0, 0.32, [1.0, 0.0, 0.4, 0.0, 0.2], 6.0, 0.01, 0.0, 0.003)]), 0.5)
	sounds[&"whistle_start"] = Synth.to_stream(Synth.concat([
		Synth.voice(2100.0, 2100.0, 0.12, [1.0, 0.1], 40.0, 0.03, 0.15, 0.005), Synth.silence(0.05),
		Synth.voice(2100.0, 2100.0, 0.35, [1.0, 0.1], 40.0, 0.03, 0.15, 0.005)]), 0.4)
	sounds[&"fanfare"] = Synth.to_stream(Synth.concat([
		Synth.voice(523.0, 523.0, 0.1, [1.0, 0.5, 0.3]), Synth.voice(659.0, 659.0, 0.1, [1.0, 0.5, 0.3]),
		Synth.voice(784.0, 784.0, 0.1, [1.0, 0.5, 0.3]), Synth.voice(1046.0, 1046.0, 0.45, [1.0, 0.5, 0.3], 6.0, 0.012)]), 0.5)
	sounds[&"fuse"] = Synth.to_stream(Synth.hit(0.8, 0.85, 0.0, 0.0, 37), 0.3)
