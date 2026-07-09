extends Node2D

# The engineer, top-down. Slower, deliberate. Dash covers real ground, grants
# i-frames and damages what it passes. Three weapons with real tradeoffs.

var game

var hx: float = 5.0
var hy: float = 5.0
var vx: float = 0.0
var vy: float = 0.0
var facing: int = 1
var aim: Vector2 = Vector2.RIGHT

var max_hp: float = 6.0
var hp: float = 6.0
var inv: float = 0.0

const SPEED: float = 62.0
const ACCEL: float = 560.0
const FRICTION: float = 620.0
const DASH_SPEED: float = 300.0
const DASH_TIME: float = 0.2
const DASH_CD: float = 0.72

var dash_cd: float = 0.0
var dash_t: float = 0.0
var dash_dir: Vector2 = Vector2.RIGHT
var dash_hits: Array = []
var trail: Array = []

var weapon: int = 0
var owned: Array = [true, false, false]
var shoot_cd: float = 0.0
var alt_cd: float = 0.0
var _prev_alt: bool = false
var speed_mult: float = 1.0
var anim: float = 0.0
var walk: float = 0.0
var muzzle_flash: float = 0.0
var recoil: float = 0.0
var land_sq: float = 0.0
var _was_dashing: bool = false
var _prev_dash: bool = false

func _process(delta: float) -> void:
	if game == null:
		return
	anim += delta
	inv = max(0.0, inv - delta)
	muzzle_flash = max(0.0, muzzle_flash - delta)
	recoil = max(0.0, recoil - delta * 6.0)
	land_sq = max(0.0, land_sq - delta * 5.0)
	if _was_dashing and dash_t <= 0.0:
		land_sq = 1.0
	_was_dashing = dash_t > 0.0
	queue_redraw()
	if not game.is_active():
		return

	shoot_cd = max(0.0, shoot_cd - delta)
	alt_cd = max(0.0, alt_cd - delta)
	dash_cd = max(0.0, dash_cd - delta)

	var mv := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): mv.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): mv.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): mv.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): mv.y += 1.0
	var _lx: float = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var _ly: float = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if Vector2(_lx, _ly).length() > 0.22:
		mv = Vector2(_lx, _ly)
	if game.mobile != null and game.mobile.move_vec.length() > 0.08:
		mv = game.mobile.move_vec
	if game.has_method("core_invert") and game.core_invert():
		mv = -mv
	mv = mv.normalized()

	var mp: Vector2 = game.world_mouse()
	if mp.distance_to(position) > 2.0:
		aim = (mp - position).normalized()
	var _rx: float = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var _ry: float = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	var _rs := Vector2(_rx, _ry)
	if _rs.length() > 0.3:
		aim = _rs.normalized()
	if game.mobile != null and game.mobile.aim_touch >= 0:
		aim = game.mobile.aim_vec
	facing = 1 if aim.x >= 0.0 else -1

	var mobile_dash: bool = game.mobile != null and game.mobile.consume_dash()
	var dash_key: bool = mobile_dash or Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_K) or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT) > 0.4 or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	if dash_key and not _prev_dash and game.abilities["dash"] and dash_cd <= 0.0 and dash_t <= 0.0:
		dash_dir = mv if mv != Vector2.ZERO else aim
		dash_t = DASH_TIME
		dash_cd = DASH_CD
		inv = max(inv, DASH_TIME + 0.08)
		dash_hits = []
		if game.audio: game.audio.sfx("dash")
	_prev_dash = dash_key

	var _trig: float = Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT)
	if (game.mobile != null and game.mobile.firing) or Input.is_key_pressed(KEY_J) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or _trig > 0.4 or _rs.length() > 0.6:
		_try_shoot()
	var alt_key: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_key_pressed(KEY_L)
	if alt_key and not _prev_alt:
		_try_alt()
	_prev_alt = alt_key

	if dash_t > 0.0:
		dash_t -= delta
		vx = dash_dir.x * DASH_SPEED
		vy = dash_dir.y * DASH_SPEED
		trail.append(position)
		if trail.size() > 7:
			trail.pop_front()
		_dash_damage()
	else:
		if not trail.is_empty():
			trail.pop_front()
		if mv != Vector2.ZERO:
			vx = move_toward(vx, mv.x * SPEED * speed_mult, ACCEL * delta)
			vy = move_toward(vy, mv.y * SPEED * speed_mult, ACCEL * delta)
		else:
			vx = move_toward(vx, 0.0, FRICTION * delta)
			vy = move_toward(vy, 0.0, FRICTION * delta)

	if (mv != Vector2.ZERO) or dash_t > 0.0:
		walk += delta * 11.0

	_move(delta)
	_check_hazard()

func cycle_weapon() -> void:
	for step in range(1, 3):
		var w: int = (weapon + step) % 3
		if owned[w]:
			weapon = w
			if game.audio: game.audio.sfx("select")
			game.say(_weapon_name())
			return

func _weapon_name() -> String:
	match weapon:
		1: return "ДРОБОВИК: страшен вблизи, бесполезен на дистанции"
		2: return "РЕЛЬСОТРОН: пробивает всех в линии, но слабее по одной цели"
		_: return "БЛАСТЕР: универсальный, быстрый"

func _try_shoot() -> void:
	if shoot_cd > 0.0:
		return
	var bonus: float = (4.0 + 2.0 * float(game.ability_lvl.get("blast", 0))) if game.abilities["blast"] else 0.0
	var muzzle: Vector2 = position + aim * (hx + 3.0)
	muzzle_flash = 0.06
	match weapon:
		1:
			shoot_cd = 0.5
			for i in range(5):
				var sp := deg_to_rad(-22.0 + 11.0 * i)
				var d: Vector2 = aim.rotated(sp)
				var bb = game.spawn_bullet(muzzle, d, "player", 9.0 + bonus * 0.5, Color(1.0, 0.85, 0.4), 165.0, 2.2)
				if bb != null: bb.life = 0.42
		2:
			shoot_cd = 0.58
			var rb = game.spawn_bullet(muzzle, aim, "player", 9.0 + bonus, Color(0.7, 0.5, 1.0), 300.0, 3.0)
			if rb != null: rb.pierce = 4
		_:
			shoot_cd = 0.22
			var bolts: int = (3 + int(game.ability_lvl.get("spread", 0))) if game.abilities["spread"] else 1
			for i in range(bolts):
				var sp2 := 0.0
				if bolts > 1:
					sp2 = deg_to_rad(-11.0 * (bolts - 1) / 2.0 + 11.0 * i)
				var d2: Vector2 = aim.rotated(sp2)
				game.spawn_bullet(muzzle, d2, "player", 10.0 + bonus, Color(0.5, 0.95, 1.0), 205.0, 2.5)
	if game.audio: game.audio.sfx("shoot")

func alt_name() -> String:
	match weapon:
		1: return "АЛЬТ: удар-выброс (отбрасывает)"
		2: return "АЛЬТ: снайпер-луч (мощный пробой)"
		_: return "АЛЬТ: заряд-взрыв"

func _try_alt() -> void:
	if alt_cd > 0.0:
		return
	var bonus: float = (4.0 + 2.0 * float(game.ability_lvl.get("blast", 0))) if game.abilities["blast"] else 0.0
	var muzzle: Vector2 = position + aim * (hx + 3.0)
	muzzle_flash = 0.12
	match weapon:
		1:
			# shotgun kick: dense close cone + self knockback
			alt_cd = 1.4
			for i in range(9):
				var sp := deg_to_rad(-32.0 + 8.0 * i)
				var d: Vector2 = aim.rotated(sp)
				var bb = game.spawn_bullet(muzzle, d, "player", 8.0 + bonus * 0.5, Color(1.0, 0.7, 0.3), 210.0, 2.4)
				if bb != null: bb.life = 0.36
			vx -= aim.x * 240.0
			vy -= aim.y * 240.0
			game.shake = max(game.shake, 0.3)
		2:
			# rail overcharge: one fat piercing beam
			alt_cd = 1.8
			var rb = game.spawn_bullet(muzzle, aim, "player", 22.0 + bonus * 2.0, Color(0.85, 0.6, 1.0), 360.0, 4.5)
			if rb != null: rb.pierce = 12
			game.shake = max(game.shake, 0.35)
		_:
			# blaster charged burst: ring of bolts
			alt_cd = 1.6
			for i in range(10):
				var a: float = TAU * i / 10.0
				var d2 := Vector2(cos(a), sin(a))
				game.spawn_bullet(position + d2 * (hx + 2.0), d2, "player", 9.0 + bonus, Color(0.5, 0.95, 1.0), 190.0, 2.5)
			game.shake = max(game.shake, 0.28)
	recoil = 1.0
	# smoke puff at the muzzle
	for _si in range(2):
		var _sd: Vector2 = aim.rotated(randf_range(-0.4, 0.4)) * randf_range(30.0, 60.0)
		game.parts.append({"x": muzzle.x, "y": muzzle.y, "vx": _sd.x, "vy": _sd.y, "t": 0.0, "life": 0.25, "col": Color(0.8, 0.8, 0.85), "r": 1.8})
	if game.audio: game.audio.sfx("shoot")

func _dash_damage() -> void:
	for e in game.enemies:
		if is_instance_valid(e) and not dash_hits.has(e):
			if e.position.distance_to(position) <= e.radius + hx + 2.0:
				e.hurt(10.0)
				dash_hits.append(e)

func _move(delta: float) -> void:
	var TILE: int = game.TILE
	position.x += vx * delta
	if vx > 0.0:
		var tx := int(floor((position.x + hx) / TILE))
		for ty in range(int(floor((position.y - hy) / TILE)), int(floor((position.y + hy - 0.01) / TILE)) + 1):
			if game.is_solid(tx, ty): position.x = tx * TILE - hx - 0.01; vx = 0.0; dash_t = 0.0; break
	elif vx < 0.0:
		var tx2 := int(floor((position.x - hx) / TILE))
		for ty in range(int(floor((position.y - hy) / TILE)), int(floor((position.y + hy - 0.01) / TILE)) + 1):
			if game.is_solid(tx2, ty): position.x = (tx2 + 1) * TILE + hx + 0.01; vx = 0.0; dash_t = 0.0; break
	position.y += vy * delta
	if vy > 0.0:
		var ty := int(floor((position.y + hy) / TILE))
		for tx in range(int(floor((position.x - hx) / TILE)), int(floor((position.x + hx - 0.01) / TILE)) + 1):
			if game.is_solid(tx, ty): position.y = ty * TILE - hy - 0.01; vy = 0.0; dash_t = 0.0; break
	elif vy < 0.0:
		var ty2 := int(floor((position.y - hy) / TILE))
		for tx in range(int(floor((position.x - hx) / TILE)), int(floor((position.x + hx - 0.01) / TILE)) + 1):
			if game.is_solid(tx, ty2): position.y = (ty2 + 1) * TILE + hy + 0.01; vy = 0.0; dash_t = 0.0; break

func _check_hazard() -> void:
	if dash_t > 0.0:
		return
	var TILE: int = game.TILE
	var tx := int(floor(position.x / TILE))
	var ty := int(floor(position.y / TILE))
	if game.tile_at(tx, ty) == "^":
		game.hazard_hit()

func hit(d: float) -> void:
	if inv > 0.0:
		return
	hp -= d
	inv = 1.0
	if game.audio: game.audio.sfx("hurt")
	if hp <= 0.0:
		hp = 0.0
		game.respawn()

func heal(d: float) -> void:
	hp = min(max_hp, hp + d)

func _draw() -> void:
	for i in range(trail.size()):
		var tp: Vector2 = trail[i] - position
		var a: float = float(i) / float(max(1, trail.size())) * 0.4
		draw_circle(tp, 5.5, Color(0.5, 0.9, 1.0, a))
	var blink: bool = inv > 0.0 and dash_t <= 0.0 and int(anim * 20.0) % 2 == 0
	if blink:
		return
	var _rk: Vector2 = -aim * recoil * 1.4
	var _sx: float = 1.0 + land_sq * 0.25
	var _sy: float = 1.0 - land_sq * 0.22
	draw_set_transform(_rk, 0.0, Vector2(_sx, _sy))
	var suit := Color(0.28, 0.52, 0.82)
	var suit_lt := Color(0.48, 0.74, 1.0)
	var suit_dk := Color(0.16, 0.30, 0.52)
	var dark := Color(0.12, 0.22, 0.4)
	var metal := Color(0.72, 0.77, 0.84)
	var step: float = sin(walk) * 1.5
	var _spd2: float = Vector2(vx, vy).length()
	var bob: float = -abs(sin(walk * 0.5)) * (1.0 if _spd2 > 8.0 else 0.0)
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	# backpack (opposite aim) with thruster glow
	var back: Vector2 = -aim * 5.5
	draw_circle(back, 3.0, suit_dk)
	draw_circle(back, 2.0, Color(0.18, 0.3, 0.42))
	var th := 0.5 + 0.5 * sin(anim * 12.0)
	if dash_t > 0.0:
		draw_circle(back, 1.6, Color(0.7, 1.0, 1.0))
	else:
		draw_circle(back, 1.0, Color(0.3, 1.0, 0.9, 0.6 + 0.4*th))
	# legs (animate step)
	var lp := Vector2(-aim.y, aim.x)  # perpendicular
	draw_rect(Rect2(-3.5, 3.0 - step, 3, 3), suit_dk)
	draw_rect(Rect2(0.5, 3.0 + step, 3, 3), suit_dk)
	draw_rect(Rect2(-3.5, 5.0 - step, 3, 1), Color(0.08, 0.14, 0.24))
	draw_rect(Rect2(0.5, 5.0 + step, 3, 1), Color(0.08, 0.14, 0.24))
	# torso with plating
	draw_rect(Rect2(-4, -3, 8, 7), suit)
	draw_rect(Rect2(-4, -3, 8, 2), suit_lt)
	draw_rect(Rect2(-4, 2, 8, 1), suit_dk)
	# chest core light
	draw_rect(Rect2(-1.5, -1, 3, 2), Color(0.3, 1.0, 0.9, 0.8))
	# shoulder pads
	draw_rect(Rect2(-5, -2, 1.5, 4), suit_dk)
	draw_rect(Rect2(3.5, -2, 1.5, 4), suit_dk)
	# helmet dome
	draw_circle(Vector2(0, -4), 3.6, suit_lt)
	draw_circle(Vector2(0, -4), 3.0, Color(0.10, 0.16, 0.24))
	# visor glow toward aim
	var vg := 0.6 + 0.4 * sin(anim * 3.0)
	draw_circle(Vector2(0, -4) + aim * 1.6, 1.3, Color(0.5, 1.0, 1.0, vg))
	draw_circle(Vector2(0, -4) + aim * 1.6, 0.6, Color(1, 1, 1))
	# antenna
	draw_rect(Rect2(-2.5, -7, 1, 2.5), metal)
	draw_circle(Vector2(-2, -7.5), 1.0, Color(1.0, 0.4, 0.3))
	# gun toward aim
	var gun: Vector2 = aim * (hx + 2.0)
	var gcol := metal
	if weapon == 1: gcol = Color(0.85, 0.72, 0.35)
	elif weapon == 2: gcol = Color(0.68, 0.5, 0.88)
	draw_line(Vector2(0,-1), gun, gcol.darkened(0.2), 3.0)
	draw_line(Vector2(0,-1), gun, gcol, 1.5)
	draw_circle(gun, 1.8, gcol.lightened(0.2))
	if muzzle_flash > 0.0:
		draw_circle(gun + aim * 2.5, 3.0, Color(1.0, 0.95, 0.6, 0.85))
		draw_circle(gun + aim * 2.5, 1.5, Color(1, 1, 1))
	# gear that accretes as abilities are collected (visible progress)
	if game != null:
		if game.abilities.get("dash", false):
			# hip dash-coil on the trailing side
			draw_circle(back * 0.6 + Vector2(0, 2.0), 1.6, Color(0.5, 0.85, 1.0))
			draw_circle(back * 0.6 + Vector2(0, 2.0), 0.8, Color(0.9, 1.0, 1.0))
		if game.abilities.get("blast", false):
			# shoulder pauldron on aim side
			var _ps: float = 4.0 * facing
			draw_rect(Rect2(_ps - 2.0, -4.5, 4.0, 3.0), Color(1.0, 0.55, 0.55))
			draw_rect(Rect2(_ps - 2.0, -4.5, 4.0, 1.0), Color(1.0, 0.75, 0.7))
		if game.abilities.get("spread", false):
			# twin barrel-fins near the gun
			var _g2: Vector2 = aim * (hx + 1.0)
			var _pp: Vector2 = Vector2(-aim.y, aim.x)
			draw_line(_g2 + _pp * 1.5, _g2 + _pp * 3.0, Color(1.0, 0.8, 0.4), 1.0)
			draw_line(_g2 - _pp * 1.5, _g2 - _pp * 3.0, Color(1.0, 0.8, 0.4), 1.0)
		if game.abilities.get("nova_hack", false):
			# wrist hack-display on the trailing arm
			var _hb: float = 0.5 + 0.5 * sin(anim * 6.0)
			draw_rect(Rect2(-facing * 5.0 - 1.5, 0.0, 3.0, 2.5), Color(0.1, 0.3, 0.2))
			draw_rect(Rect2(-facing * 5.0 - 1.0, 0.5, 2.0, 1.5), Color(0.5, 1.0, 0.7, 0.6 + 0.4 * _hb))
	if dash_t > 0.0:
		draw_circle(Vector2.ZERO, 7.5, Color(1, 1, 1, 0.3))
