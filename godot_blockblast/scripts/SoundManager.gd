extends Node

# Sound manager using AudioStreamGenerator for procedural audio

var place_player: AudioStreamPlayer
var clear_player: AudioStreamPlayer
var combo_player: AudioStreamPlayer
var gameover_player: AudioStreamPlayer
var bg_player: AudioStreamPlayer

func _ready():
	_setup_players()
	_start_background()

func _setup_players():
	place_player = _make_player(0.7)
	clear_player = _make_player(0.8)
	combo_player = _make_player(0.9)
	gameover_player = _make_player(0.6)
	bg_player = _make_player(0.15)

func _make_player(volume_db_linear: float) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.volume_db = linear_to_db(volume_db_linear)
	add_child(player)
	return player

func _generate_tone(frequency: float, duration: float, wave_type: String = "sine", fade: bool = true) -> AudioStreamWAV:
	var sample_rate = 22050
	var sample_count = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)  # 16-bit samples

	for i in range(sample_count):
		var t = float(i) / sample_rate
		var sample: float

		match wave_type:
			"sine":
				sample = sin(2.0 * PI * frequency * t)
			"square":
				sample = 1.0 if sin(2.0 * PI * frequency * t) > 0 else -1.0
			"triangle":
				var phase = fmod(t * frequency, 1.0)
				sample = 2.0 * abs(2.0 * phase - 1.0) - 1.0
			"noise":
				sample = randf_range(-1.0, 1.0)
			_:
				sample = sin(2.0 * PI * frequency * t)

		# Envelope
		var envelope = 1.0
		if fade:
			var attack = 0.01
			var release_start = duration * 0.6
			if t < attack:
				envelope = t / attack
			elif t > release_start:
				envelope = 1.0 - (t - release_start) / (duration - release_start)
			envelope = clamp(envelope, 0.0, 1.0)

		var value = int(clamp(sample * envelope, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func _generate_chord(frequencies: Array, duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var sample_count = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		for freq in frequencies:
			sample += sin(2.0 * PI * freq * t) / frequencies.size()

		var envelope = 1.0
		var release_start = duration * 0.5
		if t < 0.01:
			envelope = t / 0.01
		elif t > release_start:
			envelope = 1.0 - (t - release_start) / (duration - release_start)
		envelope = clamp(envelope, 0.0, 1.0)

		var value = int(clamp(sample * envelope, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func play_place():
	var stream = _generate_tone(220.0, 0.12, "square", true)
	place_player.stream = stream
	place_player.play()

func play_clear(combo: int = 1):
	var base_freq = 440.0
	var pitch_mult = 1.0 + (combo - 1) * 0.15
	var freqs = [base_freq * pitch_mult, base_freq * 1.25 * pitch_mult, base_freq * 1.5 * pitch_mult]
	var stream = _generate_chord(freqs, 0.4)
	clear_player.stream = stream
	clear_player.play()

func play_combo(combo: int):
	var freq = 523.25 * (1.0 + combo * 0.1)
	var stream = _generate_tone(freq, 0.3, "sine", true)
	combo_player.stream = stream
	combo_player.play()

func play_game_over():
	var stream = _generate_chord([196.0, 233.08, 293.66], 1.2)
	gameover_player.stream = stream
	gameover_player.play()

func play_invalid():
	var stream = _generate_tone(120.0, 0.08, "square", true)
	place_player.stream = stream
	place_player.play()

func _start_background():
	# Generate a simple looping ambient tone
	_play_bg_loop()

func _play_bg_loop():
	# Gentle pad chord
	var sample_rate = 22050
	var duration = 4.0
	var sample_count = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)

	var freqs = [65.41, 82.41, 98.0, 130.81]  # C2, E2, G2, C3
	for i in range(sample_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		for freq in freqs:
			sample += sin(2.0 * PI * freq * t) * 0.18
			# Add subtle harmonics
			sample += sin(2.0 * PI * freq * 2.0 * t) * 0.05

		# Gentle tremolo
		sample *= 0.7 + 0.3 * sin(2.0 * PI * 0.5 * t)

		var value = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = data

	bg_player.stream = stream
	bg_player.play()
