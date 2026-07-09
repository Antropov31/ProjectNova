extends Node

# Procedural audio. All SFX/music synthesized in code (no asset files).
# Softer, rounded tones (sine/tri based) so nothing is harsh on the ears.

const RATE := 22050
var _pool: Array = []
var _idx := 0
var _music: AudioStreamPlayer
var _sfx: Dictionary = {}
var _music_cache: Dictionary = {}
var _cur := ""
var sfx_on := true
var music_on := true
var master := 0.8
var _duck := 1.0
var _intensity := 1.0

func _ready() -> void:
	for i in range(14):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	_apply_music_vol()
	_build_all_sfx()

func _apply_music_vol() -> void:
	_music.volume_db = linear_to_db(clamp(0.32 * master * _intensity * _duck, 0.0001, 1.0))

# ---------------------------------------------------------------- helpers

func _make(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var n := samples.size()
	var d := PackedByteArray()
	d.resize(n * 2)
	for i in range(n):
		var v: float = clamp(samples[i], -1.0, 1.0)
		d.encode_s16(i * 2, int(v * 30000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = d
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = n
	return s

# soft-clip to round off edges (tanh-ish)
func _soft(x: float) -> float:
	return x / (1.0 + abs(x))

func _add_tone(buf: PackedFloat32Array, at: int, freq: float, dur: float, wave: String, vol: float, decay: float) -> void:
	var count := int(dur * RATE)
	var atk := int(0.012 * RATE)
	for i in range(count):
		var idx := at + i
		if idx < 0 or idx >= buf.size():
			continue
		var t := float(i) / RATE
		var ph := freq * t
		var ph2 := freq * 1.006 * t   # detuned twin for warmth
		var s := 0.0
		var s2 := 0.0
		match wave:
			"square": s = 0.55 if fmod(ph, 1.0) < 0.5 else -0.55; s2 = 0.55 if fmod(ph2, 1.0) < 0.5 else -0.55
			"saw": s = 2.0 * fmod(ph, 1.0) - 1.0; s2 = 2.0 * fmod(ph2, 1.0) - 1.0
			"tri": s = abs(4.0 * fmod(ph, 1.0) - 2.0) - 1.0; s2 = abs(4.0 * fmod(ph2, 1.0) - 2.0) - 1.0
			_: s = sin(ph * TAU); s2 = sin(ph2 * TAU)
		var mixed := s * 0.7 + s2 * 0.3
		# soft low-pass: blend toward a sine of the same phase for less harshness
		mixed = mixed * 0.75 + sin(ph * TAU) * 0.25
		var env := exp(-t * decay)
		if i < atk:
			env *= float(i) / float(atk)
		buf[idx] += mixed * vol * env

func _midi(n: int) -> float:
	return 440.0 * pow(2.0, (float(n) - 69.0) / 12.0)

# ---------------------------------------------------------------- sfx

func _build_all_sfx() -> void:
	_sfx["shoot"] = _sfx_shoot()
	_sfx["ehit"] = _sfx_hit()
	_sfx["hurt"] = _sfx_hurt()
	_sfx["pickup"] = _sfx_arp([72, 76, 79, 84], 0.05, "tri", 0.22)
	_sfx["heart"] = _sfx_arp([60, 64, 67, 72], 0.06, "sine", 0.24)
	_sfx["door"] = _sfx_sweep(320.0, 760.0, 0.22, 0.16)
	_sfx["gate"] = _sfx_sweep(180.0, 560.0, 0.4, 0.18)
	_sfx["dash"] = _sfx_dash()
	_sfx["blip"] = _sfx_blip()
	_sfx["select"] = _sfx_arp([72, 79], 0.05, "sine", 0.24)
	_sfx["deny"] = _sfx_arp([60, 55], 0.07, "tri", 0.22)
	_sfx["glitch"] = _sfx_glitch()
	_sfx["bosshit"] = _sfx_bosshit()
	_sfx["transform"] = _sfx_transform()
	_sfx["explode"] = _sfx_boom()
	_sfx["virus"] = _sfx_virus()
	_sfx["win"] = _sfx_arp([60, 64, 67, 72, 76, 79], 0.09, "sine", 0.26)
	_sfx["deflect"] = _sfx_deflect()
	_sfx["nova_ok"] = _sfx_vocoder([72, 76, 79], 0.5)
	_sfx["nova_warn"] = _sfx_vocoder([67, 64, 60], 0.6)
	_sfx["nova_glitch"] = _sfx_vocoder([60, 61, 59, 62], 0.9)
	_sfx["bossroar"] = _sfx_roar()

func _sfx_shoot() -> AudioStreamWAV:
	# rounded double-sine pew with a touch of body
	var buf := PackedFloat32Array(); buf.resize(int(0.12 * RATE))
	var n := buf.size()
	for i in range(n):
		var t := float(i) / RATE
		var f := 540.0 - 420.0 * (t / 0.12)
		var env := exp(-t * 22.0)
		if t < 0.008:
			env *= t / 0.008
		var body := sin(f * t * TAU) * 0.8 + sin(f * 0.5 * t * TAU) * 0.2
		buf[i] = _soft(body) * 0.15 * env
	return _make(buf, false)

func _sfx_dash() -> AudioStreamWAV:
	var buf := PackedFloat32Array(); buf.resize(int(0.18 * RATE))
	var n := buf.size()
	var last := 0.0
	for i in range(n):
		var t := float(i) / RATE
		var raw := randf() * 2.0 - 1.0
		last = last + 0.06 * (raw - last)
		var tone := sin((300.0 + 500.0 * t) * t * TAU) * 0.3
		buf[i] = (_soft(last * 2.0) * 0.1 + tone * 0.12) * exp(-t * 12.0)
	return _make(buf, false)

func _sfx_blip() -> AudioStreamWAV:
	var buf := PackedFloat32Array(); buf.resize(int(0.055 * RATE))
	_add_tone(buf, 0, 620.0, 0.055, "sine", 0.16, 20.0)
	return _make(buf, false)

func _sfx_soft_noise(dur: float, vol: float) -> AudioStreamWAV:
	var buf := PackedFloat32Array(); buf.resize(int(dur * RATE))
	var n := buf.size()
	var last := 0.0
	for i in range(n):
		var t := float(i) / RATE
		var raw := randf() * 2.0 - 1.0
		last = last + 0.12 * (raw - last)
		buf[i] = _soft(last * 1.5) * vol * exp(-t * (3.5 / dur))
	return _make(buf, false)

func _sfx_hurt() -> AudioStreamWAV:
	var buf := PackedFloat32Array(); buf.resize(int(0.22 * RATE))
	var n := buf.size()
	for i in range(n):
		var t := float(i) / RATE
		var f := 260.0 - 160.0 * t
		buf[i] = _soft(sin(f * t * TAU)) * 0.24 * exp(-t * 9.0)
	return _make(buf, false)

func _sfx_arp(notes: Array, step: float, wave: String, vol: float) -> AudioStreamWAV:
	var buf := PackedFloat32Array(); buf.resize(int(step * notes.size() * RATE) + 500)
	for i in range(notes.size()):
		_add_tone(buf, int(i * step * RATE), _midi(int(notes[i])), step + 0.06, wave, vol, 9.0)
	return _make(buf, false)

func _sfx_sweep(f0: float, f1: float, dur: float, vol: float) -> AudioStreamWAV:
	var buf := PackedFloat32Array(); buf.resize(int(dur * RATE))
	var n := buf.size()
	for i in range(n):
		var t := float(i) / RATE
		var f: float = lerp(f0, f1, t / dur)
		buf[i] = _soft(sin(f * t * TAU)) * vol * exp(-t * 3.5)
	return _make(buf, false)

func _sfx_glitch() -> AudioStreamWAV:
	var buf := PackedFloat32Array(); buf.resize(int(0.2 * RATE))
	var n := buf.size()
	for i in range(n):
		var t := float(i) / RATE
		var block := int(t * 36.0)
		var f := 180.0 + float(block % 5) * 300.0
		var s := sin(f * t * TAU)
		if (block % 3) == 0:
			s = (randf() * 2.0 - 1.0) * 0.6
		buf[i] = _soft(s) * 0.14 * exp(-t * 3.0)
	return _make(buf, false)

func _sfx_virus() -> AudioStreamWAV:
	# a wet, detuned laugh-like warble for the virus computer
	var buf := PackedFloat32Array(); buf.resize(int(0.9 * RATE))
	var n := buf.size()
	for i in range(n):
		var t := float(i) / RATE
		var wob := sin(t * 9.0) * 40.0
		var a := sin((120.0 + wob) * t * TAU)
		var b := sin((123.0 + wob) * t * TAU)
		buf[i] = _soft((a + b) * 0.5) * 0.2 * (0.6 + 0.4 * sin(t * 14.0))
	return _make(buf, false)

func _sfx_transform() -> AudioStreamWAV:
	var buf := PackedFloat32Array(); buf.resize(int(2.4 * RATE))
	var n := buf.size()
	for i in range(n):
		var t := float(i) / RATE
		var f := 55.0 + t * 34.0
		var rumble := sin(f * t * TAU) * 0.4
		var grind := (randf() * 2.0 - 1.0) * 0.1 * (t / 2.4)
		var env: float = clamp(t - 1.1, 0.0, 1.0)
		var screech: float = sin((520.0 + sin(t * 5.0) * 200.0) * t * TAU) * 0.1 * env
		var amp: float = clamp(1.0 - abs(t - 1.7) * 0.4, 0.2, 1.0)
		buf[i] = _soft(rumble + grind + screech) * amp * 0.7
	return _make(buf, false)

func _sfx_hit() -> AudioStreamWAV:
	# crisp metallic tick + short noise transient
	var buf := PackedFloat32Array(); buf.resize(int(0.09 * RATE))
	var n := buf.size()
	var last := 0.0
	for i in range(n):
		var t := float(i) / RATE
		var raw := randf() * 2.0 - 1.0
		last = last * 0.4 + raw * 0.6
		var tick := sin(1400.0 * t * TAU) * exp(-t * 90.0)
		buf[i] = _soft(last * 0.5 + tick * 0.6) * 0.16 * exp(-t * 26.0)
	return _make(buf, false)

func _sfx_bosshit() -> AudioStreamWAV:
	# heavier thunk with a low body
	var buf := PackedFloat32Array(); buf.resize(int(0.16 * RATE))
	var n := buf.size()
	for i in range(n):
		var t := float(i) / RATE
		var body := sin((180.0 - 90.0 * t / 0.16) * t * TAU)
		var tick := (randf() * 2.0 - 1.0) * exp(-t * 40.0)
		buf[i] = _soft(body * 0.7 + tick * 0.3) * 0.22 * exp(-t * 12.0)
	return _make(buf, false)

func _sfx_boom() -> AudioStreamWAV:
	# layered explosion: sub thump + filtered noise tail
	var buf := PackedFloat32Array(); buf.resize(int(0.55 * RATE))
	var n := buf.size()
	var last := 0.0
	for i in range(n):
		var t := float(i) / RATE
		var sub := sin((70.0 - 30.0 * clamp(t / 0.3, 0.0, 1.0)) * t * TAU)
		var raw := randf() * 2.0 - 1.0
		last = last + 0.10 * (raw - last)
		buf[i] = _soft(sub * 0.5 + last * 1.6 * 0.5) * 0.34 * exp(-t * 6.0)
	return _make(buf, false)

func _sfx_deflect() -> AudioStreamWAV:
	# bright ping with shimmer
	var buf := PackedFloat32Array(); buf.resize(int(0.14 * RATE))
	var n := buf.size()
	for i in range(n):
		var t := float(i) / RATE
		var a1 := sin(1600.0 * t * TAU)
		var a2 := sin(2400.0 * t * TAU)
		buf[i] = _soft(a1 * 0.6 + a2 * 0.4) * 0.14 * exp(-t * 20.0)
	return _make(buf, false)

func _sfx_roar() -> AudioStreamWAV:
	# guttural boss roar: detuned low saws with slow wobble
	var buf := PackedFloat32Array(); buf.resize(int(1.1 * RATE))
	var n := buf.size()
	for i in range(n):
		var t := float(i) / RATE
		var wob := sin(t * 6.0) * 12.0
		var f := 70.0 + wob
		var s1 := 2.0 * fmod(f * t, 1.0) - 1.0
		var s2 := 2.0 * fmod((f * 1.5) * t, 1.0) - 1.0
		var env: float = clamp(t / 0.15, 0.0, 1.0) * exp(-t * 2.2)
		buf[i] = _soft(s1 * 0.5 + s2 * 0.3) * 0.28 * env
	return _make(buf, false)

func _sfx_vocoder(notes: Array, dur: float) -> AudioStreamWAV:
	# a soft robotic 'voice' stinger: formant-ish stacked sines with tremolo
	var buf := PackedFloat32Array(); buf.resize(int(dur * RATE) + 400)
	var step := dur / float(max(1, notes.size()))
	for ni in range(notes.size()):
		var base := _midi(int(notes[ni]))
		var at := int(ni * step * RATE)
		var cnt := int(step * 1.1 * RATE)
		for i in range(cnt):
			var idx := at + i
			if idx < 0 or idx >= buf.size(): continue
			var t := float(i) / RATE
			# carrier + two formants
			var v := sin(base * t * TAU) * 0.5
			v += sin(base * 2.0 * t * TAU) * 0.25
			v += sin(base * 3.0 * t * TAU) * 0.15
			# vocoder tremolo
			var trem := 0.6 + 0.4 * sin(t * 40.0)
			var env := exp(-t * 4.0)
			if t < 0.02: env *= t / 0.02
			buf[idx] += _soft(v * trem) * 0.12 * env
	return _make(buf, false)

func sfx(name: String) -> void:
	if not sfx_on:
		return
	var st = _sfx.get(name)
	if st == null:
		return
	var p: AudioStreamPlayer = _pool[_idx]
	_idx = (_idx + 1) % _pool.size()
	p.stream = st
	p.volume_db = linear_to_db(clamp(master, 0.0001, 1.0))
	p.play()

# ---------------------------------------------------------------- music

func play_music(mood: String) -> void:
	if mood == _cur:
		return
	_cur = mood
	if not _music_cache.has(mood):
		_music_cache[mood] = _build_music(mood)
	_music.stream = _music_cache[mood]
	if music_on:
		_music.play()

func set_intensity(high: bool) -> void:
	_music.pitch_scale = 1.06 if high else 1.0
	_intensity = 1.38 if high else 1.0
	_apply_music_vol()

func set_duck(on: bool) -> void:
	var target := 0.4 if on else 1.0
	if abs(target - _duck) > 0.01:
		_duck = target
		_apply_music_vol()

func stop_music() -> void:
	_music.stop()

func set_master(v: float) -> void:
	master = clamp(v, 0.0, 1.0)
	_apply_music_vol()

func toggle_music(on: bool) -> void:
	music_on = on
	if on:
		if _cur != "":
			_music.play()
	else:
		_music.stop()

func _hat(buf: PackedFloat32Array, at: int, dur: float, vol: float) -> void:
	var count := int(dur * RATE)
	var last := 0.0
	for i in range(count):
		var idx := at + i
		if idx < 0 or idx >= buf.size():
			continue
		var t := float(i) / RATE
		var raw := randf() * 2.0 - 1.0
		last = last * 0.3 + raw * 0.7
		buf[idx] += _soft(last) * vol * exp(-t * 60.0)

func _build_music(mood: String) -> AudioStreamWAV:
	var root := 45
	var bpm := 96.0
	var wave := "tri"
	var arp := [0, 3, 7, 10]
	var bassvol := 0.18
	var arpvol := 0.10
	match mood:
		"menu": root = 45; bpm = 68.0; wave = "sine"; arp = [0, 7, 12, 7]; arpvol = 0.10
		"maint": root = 45; bpm = 94.0; wave = "tri"; arp = [0, 3, 7, 10]
		"assembly": root = 43; bpm = 112.0; wave = "tri"; arp = [0, 3, 6, 10]; arpvol = 0.10
		"core": root = 40; bpm = 124.0; wave = "tri"; arp = [0, 1, 6, 8]; arpvol = 0.11
		"server": root = 42; bpm = 108.0; wave = "square"; arp = [0, 5, 7, 12]; arpvol = 0.09
		"tech": root = 38; bpm = 100.0; wave = "saw"; arp = [0, 2, 5, 7]; bassvol = 0.2; arpvol = 0.09
		"approach": root = 39; bpm = 132.0; wave = "saw"; arp = [0, 1, 6, 7]; bassvol = 0.2; arpvol = 0.11
		"boss": root = 38; bpm = 146.0; wave = "saw"; arp = [0, 6, 7, 11]; bassvol = 0.2; arpvol = 0.12
		"bossintro": root = 36; bpm = 60.0; wave = "sine"; arp = [0, 1, 0, -1]; bassvol = 0.22; arpvol = 0.07
	var steps := 16
	var step_dur := 60.0 / bpm / 2.0
	var total := int(step_dur * steps * RATE) + 900
	var buf := PackedFloat32Array(); buf.resize(total)
	for s in range(steps):
		var at := int(s * step_dur * RATE)
		if s % 4 == 0:
			_add_tone(buf, at, _midi(root - 24), step_dur * 2.2, "sine", bassvol * 0.9, 1.8)  # warm sub
			_add_tone(buf, at, _midi(root - 12), step_dur * 2.0, wave, bassvol, 2.5)
		if s % 2 == 0:
			_add_tone(buf, at, _midi(root), step_dur * 1.2, wave, bassvol * 0.7, 3.5)
		var note: int = root + 12 + int(arp[s % arp.size()])
		_add_tone(buf, at, _midi(note), step_dur * 0.9, wave, arpvol, 4.5)
		_add_tone(buf, at, _midi(note + 12), step_dur * 0.4, "sine", arpvol * 0.35, 6.0)  # soft octave shimmer
		if s % 2 == 1:
			_hat(buf, at, step_dur * 0.3, 0.03)  # gentle hi-hat
		if mood == "boss" and s % 2 == 1:
			_add_tone(buf, at, _midi(note + 12), step_dur * 0.5, "tri", arpvol * 0.6, 7.0)
	return _make(buf, true)
