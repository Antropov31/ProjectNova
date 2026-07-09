extends Node2D

# Top-down infected robots with detailed pixel sprites.
#  - separation: they push apart so a crowd never stacks
#  - telegraphs: turret/hunter/elite flash ~0.4s before firing
#   ground - chaser   fly - swarm   turret - anchored   hunter - kite   elite - miniboss

var game
var player
var kind: String = "ground"
var hp: float = 22.0
var max_hp: float = 22.0
var radius: float = 6.0
var touch_dmg: float = 1.0
var hurt_t: float = 0.0
var anim: float = 0.0
var fire_cd: float = 1.2
var tele: float = 0.0
var face: int = 1
var spawn_grow: float = 0.0
var charge_t: float = 0.0
var hacked: float = 0.0
var _dead: bool = false
var tint: float = 0.0
var vphase: float = 0.0
var vscale: float = 1.0
var variant: int = 0
var shield_t: float = 2.6
var shield_up: bool = true
var heal_cd: float = 2.4
var burn_t: float = 0.0
var slow_t: float = 0.0
var _burn_acc: float = 0.0

func _ready() -> void:
	spawn_grow = 0.35
	if kind == "turret":
		radius = 7.0
	elif kind == "elite":
		radius = 12.0
	elif kind == "bomber":
		radius = 6.5
	elif kind == "shielder":
		radius = 8.0
	elif kind == "healer":
		radius = 6.5
	anim = randf() * 6.0
	var sid: int = get_instance_id()
	tint = float(sid % 100) / 100.0 - 0.5
	vphase = float(sid % 628) / 100.0
	vscale = 1.0 + (float(sid % 40) / 40.0 - 0.5) * 0.14
	variant = sid % 3

func is_elite() -> bool:
	return kind == "elite"

func _process(delta: float) -> void:
	if game == null or not game.is_active():
		return
	if player == null or not is_instance_valid(player):
		return
	anim += delta
	hurt_t = max(0.0, hurt_t - delta)
	fire_cd = max(0.0, fire_cd - delta)
	tele = max(0.0, tele - delta)
	spawn_grow = max(0.0, spawn_grow - delta)
	hacked = max(0.0, hacked - delta)
	burn_t = max(0.0, burn_t - delta)
	slow_t = max(0.0, slow_t - delta)
	if burn_t > 0.0:
		_burn_acc += delta
		if _burn_acc >= 0.4:
			_burn_acc = 0.0
			hurt(2.0)
	var spd: float = game.enemy_speed_mult()
	if slow_t > 0.0: spd *= 0.45
	if hacked > 0.0:
		# recruited: escorts you, no longer attacks other enemies
		var _hd: Vector2 = player.position - position
		if _hd.length() > 34.0:
			_move(_hd.normalized(), 44.0 * spd, delta)
		_separate(delta)
		queue_redraw()
		return
	match kind:
		"fly": _fly(delta, spd)
		"turret": _turret(delta)
		"hunter": _hunter(delta, spd)
		"elite": _elite(delta, spd)
		"bomber": _bomber(delta, spd)
		"shielder": _shielder(delta, spd)
		"healer": _healer(delta, spd)
		_: _ground(delta, spd)
	_separate(delta)
	queue_redraw()

func _target():
	if hacked > 0.0:
		var best = null
		var bd := 999999.0
		for e in game.enemies:
			if e == self or not is_instance_valid(e) or e.hacked > 0.0:
				continue
			var dd: float = e.position.distance_to(position)
			if dd < bd:
				bd = dd; best = e
		if best != null:
			return best
	return player

func _to() -> Vector2:
	var t = _target()
	if t == null or not is_instance_valid(t):
		return Vector2.RIGHT
	return t.position - position

func _separate(delta: float) -> void:
	var push := Vector2.ZERO
	for e in game.enemies:
		if e == self or not is_instance_valid(e):
			continue
		var d: Vector2 = position - e.position
		var dist: float = d.length()
		var mind: float = radius + e.radius
		if dist > 0.01 and dist < mind:
			push += d.normalized() * (mind - dist)
	if push != Vector2.ZERO:
		var np: Vector2 = position + push * clamp(delta * 8.0, 0.0, 1.0)
		if not _solid_at(np.x, position.y): position.x = np.x
		if not _solid_at(position.x, np.y): position.y = np.y

func _move(dir: Vector2, speed: float, delta: float) -> void:
	var nx: float = position.x + dir.x * speed * delta
	if not _solid_at(nx, position.y):
		position.x = nx
	var ny: float = position.y + dir.y * speed * delta
	if not _solid_at(position.x, ny):
		position.y = ny
	face = 1 if dir.x >= 0.0 else -1

func _solid_at(px: float, py: float) -> bool:
	var TILE: int = game.TILE
	for ox in [-radius, radius]:
		for oy in [-radius, radius]:
			if game.is_solid(int(floor((px + ox) / TILE)), int(floor((py + oy) / TILE))):
				return true
	return false

func _shoot(speed: float, col: Color) -> void:
	var d: Vector2 = _to().normalized()
	var team := "player" if hacked > 0.0 else "enemy"
	game.spawn_bullet(position + d * (radius + 3.0), d, team, 1.0, col, speed, 3.0)
	if game.audio: game.audio.sfx("blip")

func _ground(delta: float, spd: float) -> void:
	_move(_to().normalized(), 46.0 * spd, delta)

func _fly(delta: float, spd: float) -> void:
	var d: Vector2 = _to().normalized().rotated(sin(anim * 4.0 + vphase) * 0.4)
	_move(d, 66.0 * spd, delta)

func _turret(delta: float) -> void:
	if _to().length() < 155.0 and fire_cd <= 0.0 and tele <= 0.0:
		tele = 0.45
	if tele > 0.0 and tele < 0.05:
		fire_cd = 1.5
		_shoot(120.0, Color(1.0, 0.6, 0.2))

func _hunter(delta: float, spd: float) -> void:
	var to: Vector2 = _to()
	var dist: float = to.length()
	var dir: Vector2 = to.normalized()
	var mv := Vector2.ZERO
	if dist > 84.0: mv += dir
	elif dist < 60.0: mv -= dir
	mv += Vector2(-dir.y, dir.x) * sin(anim * 1.6) * 0.6
	_move(mv.normalized(), 52.0 * spd, delta)
	if dist < 175.0 and fire_cd <= 0.0 and tele <= 0.0:
		tele = 0.4
	if tele > 0.0 and tele < 0.05:
		fire_cd = 1.6
		_shoot(112.0, Color(0.6, 0.9, 1.0))

func _elite(delta: float, spd: float) -> void:
	var to: Vector2 = _to()
	var dist: float = to.length()
	if charge_t > 0.0:
		charge_t -= delta
		_move(to.normalized(), 150.0 * spd, delta)
	else:
		_move(to.normalized(), 34.0 * spd, delta)
		if fire_cd <= 0.0 and tele <= 0.0:
			tele = 0.5
		if tele > 0.0 and tele < 0.05:
			fire_cd = 2.0
			var n := 10
			for i in range(n):
				var a := TAU * i / n + anim
				var team := "player" if hacked > 0.0 else "enemy"
				game.spawn_bullet(position + Vector2(cos(a), sin(a)) * (radius + 2.0), Vector2(cos(a), sin(a)), team, 1.0, Color(1.0, 0.4, 0.5), 82.0, 3.0)
			if game.audio: game.audio.sfx("blip")
			if dist < 120.0 and randf() < 0.5:
				charge_t = 0.5

func _bomber(delta: float, spd: float) -> void:
	if charge_t > 0.0:
		charge_t -= delta
		_move(_to().normalized(), 18.0 * spd, delta)
		if charge_t <= 0.0:
			hurt(9999.0)
		return
	_move(_to().normalized(), 46.0 * spd, delta)
	if _to().length() < 22.0:
		charge_t = 0.5
		if game.audio: game.audio.sfx("blip")

func _shielder(delta: float, spd: float) -> void:
	shield_t -= delta
	if shield_t <= 0.0:
		shield_up = not shield_up
		shield_t = 2.6 if shield_up else 1.3
	var to: Vector2 = _to()
	if to.length() > 40.0:
		_move(to.normalized(), 30.0 * spd, delta)
	if fire_cd <= 0.0 and to.length() < 150.0:
		fire_cd = 2.0
		_shoot(90.0, Color(0.6, 0.8, 1.0))

func shield_blocks(bpos: Vector2) -> bool:
	if kind != "shielder" or not shield_up:
		return false
	return (bpos - position).normalized().dot(_eye()) > 0.25

func _healer(delta: float, spd: float) -> void:
	var to: Vector2 = _to()
	var dist: float = to.length()
	if dist < 95.0:
		_move((-to).normalized(), 42.0 * spd, delta)
	else:
		_move(Vector2(-to.y, to.x).normalized(), 22.0 * spd, delta)
	heal_cd -= delta
	if heal_cd <= 0.0:
		heal_cd = 2.4
		_do_heal()

func _do_heal() -> void:
	var healed := false
	for o in game.enemies:
		if o != self and is_instance_valid(o) and o.hacked <= 0.0 and o.hp < o.max_hp and o.position.distance_to(position) < 64.0:
			o.hp = min(o.max_hp, o.hp + 6.0)
			healed = true
	if healed:
		if game.audio: game.audio.sfx("pickup")
		for i in range(8):
			var a: float = TAU * i / 8.0
			game.parts.append({"x": position.x, "y": position.y, "vx": cos(a) * 50.0, "vy": sin(a) * 50.0, "t": 0.0, "life": 0.5, "col": Color(0.4, 1.0, 0.6), "r": 1.5})

func hurt(d: float) -> void:
	if _dead:
		return
	hp -= d
	hurt_t = 0.1
	if game.audio: game.audio.sfx("ehit")
	if hp <= 0.0:
		_dead = true
		if kind == "bomber" and is_instance_valid(player) and player.position.distance_to(position) < 30.0:
			player.hit(2.0)
			game.shake = max(game.shake, 0.45)
		if game.audio: game.audio.sfx("explode")
		game.enemy_killed(self)

func hack() -> void:
	hacked = 6.0

func _draw() -> void:
	var scx: float = 1.0
	var scy: float = 1.0
	if spawn_grow > 0.0:
		var _g2: float = 1.0 - spawn_grow / 0.35
		scx = _g2; scy = _g2
	if hurt_t > 0.0:
		var _hf: float = hurt_t / 0.1
		scx *= 1.0 + 0.28 * _hf
		scy *= 1.0 - 0.22 * _hf
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(scx * vscale, scy * vscale))
	draw_circle(Vector2(0, radius * 0.7), radius, Color(0, 0, 0, 0.25))
	if tele > 0.0:
		var tf: float = 1.0 - tele / 0.5
		draw_arc(Vector2.ZERO, radius + 3.0, 0.0, TAU * tf, 20, Color(1.0, 0.9, 0.3, 0.8), 1.5)
	match kind:
		"fly": _draw_fly()
		"turret": _draw_turret()
		"hunter": _draw_hunter()
		"elite": _draw_elite()
		"bomber": _draw_bomber()
		"shielder": _draw_shielder()
		"healer": _draw_healer()
		_: _draw_ground()
	# per-instance wear so a crowd never looks like clones
	if tint > 0.2:
		draw_line(Vector2(-radius * 0.4 + tint, -radius * 0.3), Vector2(radius * 0.3, radius * 0.2 * tint), Color(0.0, 0.0, 0.0, 0.22), 1.0)
	elif tint < -0.2:
		draw_rect(Rect2(radius * 0.2, -radius * 0.4, 1.5, 1.5), Color(0.0, 0.0, 0.0, 0.20))
	if hacked > 0.0:
		draw_circle(Vector2(0, -radius - 4), 1.5, Color(0.4, 1.0, 0.9))
		draw_arc(Vector2.ZERO, radius + 2.0, 0.0, TAU, 16, Color(0.4, 1.0, 0.9, 0.5), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if hp < max_hp:
		var frac: float = clamp(hp / max_hp, 0.0, 1.0)
		var bw: float = radius * 2.0
		draw_rect(Rect2(-radius, -radius - 4, bw, 1.5), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-radius, -radius - 4, bw * frac, 1.5), Color(1.0, 0.5, 0.4))

func _flash() -> bool:
	return hurt_t > 0.0

func _eye() -> Vector2:
	return _to().normalized()

# ---- detailed sprites (chunky pixels, plating, shading) ----

func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)

func _draw_ground() -> void:
	# tracked chaser: treads, plated body, hazard stripe, angry eye
	var _vp: Array = [[Color(0.78,0.26,0.22),Color(0.95,0.4,0.32),Color(0.45,0.12,0.11)],[Color(0.82,0.42,0.16),Color(1.0,0.6,0.28),Color(0.5,0.22,0.06)],[Color(0.66,0.2,0.34),Color(0.9,0.36,0.52),Color(0.4,0.1,0.2)]][variant % 3]
	var body: Color = _vp[0]
	var body_lt: Color = _vp[1]
	var body_dk: Color = _vp[2]
	if hacked > 0.0:
		body = Color(0.25, 0.62, 0.62); body_lt = Color(0.4, 0.85, 0.85); body_dk = Color(0.12, 0.35, 0.35)
	if _flash(): body = Color(1,1,1); body_lt = Color(1,1,1); body_dk = Color(0.8,0.8,0.8)
	var r := radius
	var tread := sin(anim * 12.0)
	# side treads
	for sidx in [-1, 1]:
		var tx: float = sidx * (r - 1) - 1.5
		_px(tx, -r, 3, r * 2.0, Color(0.12, 0.10, 0.11))
		for ti in range(3):
			var ty: float = -r + 2.0 + ti * 4.0 + (2.0 if tread > 0 else 0.0)
			_px(tx, ty, 3, 1.5, Color(0.32, 0.28, 0.28))
	# chassis
	_px(-r + 1, -r + 1, r * 2.0 - 2, r * 2.0 - 2, body)
	_px(-r + 1, -r + 1, r * 2.0 - 2, 2, body_lt)
	_px(-r + 1, r - 3, r * 2.0 - 2, 2, body_dk)
	# hazard stripe
	_px(-r + 1, -1, r * 2.0 - 2, 2, Color(0.95, 0.82, 0.2))
	_px(-r + 1, -1, 2, 2, body_dk)
	_px(r - 3, -1, 2, 2, body_dk)
	# rivets
	_px(-r + 2, -r + 3, 1, 1, body_lt)
	_px(r - 3, -r + 3, 1, 1, body_lt)
	# angry eye visor
	var e := _eye()
	_px(-3 + e.x * 1.5, -3, 6, 3, Color(0.15, 0.03, 0.03))
	_px(-2 + e.x * 1.5, -2.5, 4, 2, Color(1.0, 0.85, 0.2))
	_px(-2 + e.x * 1.5, -2.5, 1, 2, Color(1.0, 1.0, 0.6))
	# blinking rear beacon + faint heat exhaust
	if int(anim * 4.0) % 2 == 0:
		draw_circle(Vector2(-e.x * (r + 1.0), -r + 1.0), 1.0, Color(1.0, 0.5, 0.2, 0.7))
	var exx: float = -e.x * (r + 2.0)
	draw_circle(Vector2(exx, r - 1.0), 1.5 + abs(sin(anim * 10.0)) * 1.0, Color(0.9, 0.5, 0.2, 0.15))

func _draw_fly() -> void:
	# drone with spinning rotors, glass canopy, blinking sensor
	var body := Color(0.55, 0.32, 0.72)
	var body_lt := Color(0.75, 0.5, 0.95)
	if hacked > 0.0: body = Color(0.25, 0.62, 0.62); body_lt = Color(0.4, 0.85, 0.85)
	if _flash(): body = Color(1,1,1); body_lt = Color(1,1,1)
	var r := radius
	var w: float = 4.0 + abs(sin(anim * 26.0)) * 4.0
	# rotor blur
	draw_circle(Vector2(-r, -1), w * 0.5, Color(0.7, 0.7, 0.9, 0.35))
	draw_circle(Vector2(r, -1), w * 0.5, Color(0.7, 0.7, 0.9, 0.35))
	_px(-r - 1, -1.5, 2, 1, Color(0.5,0.5,0.6))
	_px(r - 1, -1.5, 2, 1, Color(0.5,0.5,0.6))
	# body pod
	draw_circle(Vector2.ZERO, r, body)
	draw_circle(Vector2(0, -1), r * 0.7, body_lt)
	draw_circle(Vector2(0, -1), r * 0.5, Color(0.2, 0.1, 0.3))
	# glowing eye
	var e := _eye()
	draw_circle(e * 2.0, 2.0, Color(1.0, 0.3, 0.2))
	draw_circle(e * 2.0, 1.0, Color(1.0, 0.9, 0.5))
	# underlight blinker
	if int(anim * 6.0) % 2 == 0:
		_px(-1, r - 1, 2, 1.5, Color(1.0, 0.3, 0.3))

func _draw_turret() -> void:
	# bolted base + rotating barrel + charge glow
	var dome := Color(0.9, 0.55, 0.2)
	if _flash(): dome = Color(1,1,1)
	var r := radius
	# base plate
	_px(-r, r - 3, r * 2.0, 4, Color(0.22, 0.2, 0.22))
	_px(-r, r - 3, r * 2.0, 1, Color(0.4, 0.36, 0.36))
	# bolts
	_px(-r + 1, r - 2, 1, 1, Color(0.5, 0.46, 0.46))
	_px(r - 2, r - 2, 1, 1, Color(0.5, 0.46, 0.46))
	# dome
	draw_circle(Vector2(0, -1), r, Color(0.3, 0.26, 0.24))
	draw_circle(Vector2(0, -1), r - 1.5, dome)
	draw_circle(Vector2(0, -1), r * 0.4, Color(0.35, 0.14, 0.06))
	draw_circle(Vector2(0, -1), r * 0.4, Color(0.35, 0.14, 0.06))
	# barrel
	var d := _eye()
	draw_line(Vector2(0,-1), Vector2(0,-1) + d * (r + 5.0), Color(0.28, 0.26, 0.3), 3.0)
	draw_line(Vector2(0,-1), Vector2(0,-1) + d * (r + 5.0), Color(0.45, 0.42, 0.48), 1.0)
	var glow: float = 0.35
	if tele > 0.0: glow = 1.0
	draw_circle(Vector2(0,-1) + d * (r + 5.0), 1.6, Color(1.0, 0.3 + glow * 0.6, 0.1))

func _draw_hunter() -> void:
	# sleek diamond interceptor with wing rotors and scope eye
	var body := Color(0.28, 0.55, 0.88)
	var body_lt := Color(0.5, 0.78, 1.0)
	if hacked > 0.0: body = Color(0.25, 0.62, 0.62); body_lt = Color(0.4, 0.85, 0.85)
	if _flash(): body = Color(1,1,1); body_lt = Color(1,1,1)
	var r := radius
	var w: float = 3.5 + abs(sin(anim * 30.0)) * 2.5
	draw_circle(Vector2(-r, -r * 0.4), w * 0.5, Color(0.7, 0.85, 1.0, 0.4))
	draw_circle(Vector2(r, -r * 0.4), w * 0.5, Color(0.7, 0.85, 1.0, 0.4))
	# diamond hull
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)]), body)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -r), Vector2(r * 0.6, -r * 0.3), Vector2(0, 0), Vector2(-r * 0.6, -r * 0.3)]), body_lt)
	draw_circle(Vector2.ZERO, r * 0.35, Color(0.1, 0.2, 0.35))
	var ec := Color(0.4, 0.9, 1.0)
	if tele > 0.0: ec = Color(1.0, 0.9, 0.3)
	var e := _eye()
	draw_circle(e * 2.2, 1.8, ec)
	draw_circle(e * 2.2, 0.8, Color(1, 1, 1))
	# twin engine glow at the tail
	var tail := -e
	var eg: float = 0.5 + 0.5 * sin(anim * 14.0)
	draw_circle(tail * (r + 1.0) + Vector2(-tail.y, tail.x) * 2.0, 1.4, Color(0.5, 0.85, 1.0, 0.4 + 0.3 * eg))
	draw_circle(tail * (r + 1.0) - Vector2(-tail.y, tail.x) * 2.0, 1.4, Color(0.5, 0.85, 1.0, 0.4 + 0.3 * eg))

func _draw_elite() -> void:
	# armoured hexagon miniboss with layered plating and core
	var body := Color(0.66, 0.2, 0.48)
	var body_lt := Color(0.85, 0.35, 0.62)
	if _flash(): body = Color(1,1,1); body_lt = Color(1,1,1)
	if charge_t > 0.0: body = Color(1.0, 0.45, 0.32); body_lt = Color(1.0, 0.6, 0.4)
	var r := radius
	# outer hex
	var pts := PackedVector2Array()
	for i in range(6):
		var a := TAU * i / 6.0 + anim * 0.3
		pts.append(Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, body)
	# inner hex highlight
	var pts2 := PackedVector2Array()
	for i in range(6):
		var a := TAU * i / 6.0 + anim * 0.3
		pts2.append(Vector2(cos(a), sin(a)) * r * 0.72)
	draw_colored_polygon(pts2, body_lt)
	draw_circle(Vector2.ZERO, r * 0.5, Color(0.2, 0.05, 0.12))
	var core := Color(1.0, 0.5, 0.2)
	if tele > 0.0: core = Color(1.0, 0.9, 0.3)
	var pulse: float = 0.6 + 0.4 * sin(anim * 5.0)
	draw_circle(Vector2.ZERO, r * 0.3, Color(core.r, core.g, core.b, pulse))
	draw_circle(_eye() * r * 0.35, 2.5, Color(1.0, 0.95, 0.4))
	# armor bolts on each vertex
	for i in range(6):
		var a2 := TAU * i / 6.0 + anim * 0.3
		var d := Vector2(cos(a2), sin(a2))
		draw_circle(d * r * 0.85, 1.0, Color(0.35, 0.1, 0.22))
		draw_line(d * r, d * (r + 3.0), Color(0.4, 0.1, 0.25), 2.0)


func _draw_bomber() -> void:
	var fuse: bool = charge_t > 0.0
	var body := Color(0.85, 0.35, 0.12)
	if fuse and int(anim * 20.0) % 2 == 0: body = Color(1.0, 0.9, 0.3)
	if _flash(): body = Color(1, 1, 1)
	var r := radius
	draw_circle(Vector2.ZERO, r, body)
	draw_circle(Vector2(0, -1), r * 0.6, body.lightened(0.2))
	for i in range(6):
		var a := TAU * i / 6.0
		draw_circle(Vector2(cos(a), sin(a)) * r * 0.8, 0.9, Color(0.2, 0.1, 0.05))
	draw_line(Vector2(0, -r), Vector2(1.5, -r - 4.0), Color(0.3, 0.3, 0.3), 1.0)
	var fc := Color(1.0, 0.6, 0.2)
	if fuse: fc = Color(1.0, 0.95, 0.5)
	draw_circle(Vector2(1.5, -r - 4.0), 1.4, fc)
	draw_circle(_eye() * r * 0.3, 1.8, Color(1.0, 0.9, 0.3))

func _draw_shielder() -> void:
	var body := Color(0.3, 0.4, 0.55)
	if _flash(): body = Color(1, 1, 1)
	var r := radius
	draw_rect(Rect2(-r * 0.8, -r * 0.8, r * 1.6, r * 1.6), body)
	draw_rect(Rect2(-r * 0.8, -r * 0.8, r * 1.6, 2.0), body.lightened(0.3))
	draw_circle(_eye() * r * 0.3, 2.0, Color(0.6, 0.85, 1.0))
	var sd := _eye()
	var ba := atan2(sd.y, sd.x)
	var scol := Color(0.4, 0.75, 1.0, 0.85) if shield_up else Color(0.4, 0.7, 1.0, 0.2)
	draw_arc(Vector2.ZERO, r + 4.0, ba - 0.9, ba + 0.9, 16, scol, 2.5 if shield_up else 1.0)
	if shield_up:
		draw_arc(Vector2.ZERO, r + 6.0, ba - 0.8, ba + 0.8, 16, Color(0.7, 0.9, 1.0, 0.4), 1.0)

func _draw_healer() -> void:
	var body := Color(0.2, 0.55, 0.35)
	if _flash(): body = Color(1, 1, 1)
	var r := radius
	var pulse := 0.5 + 0.5 * sin(anim * 4.0)
	draw_arc(Vector2.ZERO, r + 3.0 + pulse * 2.0, 0.0, TAU, 20, Color(0.4, 1.0, 0.6, 0.25), 1.0)
	draw_circle(Vector2.ZERO, r, body)
	draw_circle(Vector2(0, -1), r * 0.6, body.lightened(0.2))
	var cc := Color(0.5, 1.0, 0.6, 0.7 + 0.3 * pulse)
	draw_rect(Rect2(-1.0, -r * 0.5, 2.0, r), cc)
	draw_rect(Rect2(-r * 0.5, -1.0, r, 2.0), cc)
	draw_circle(_eye() * r * 0.3, 1.6, Color(0.7, 1.0, 0.8))
