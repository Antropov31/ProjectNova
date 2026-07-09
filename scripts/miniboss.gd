extends Node2D

# Zone bosses / minibosses. One script, many archetypes (arch). They now talk:
# a spawn taunt and occasional lines, shown as a speech bubble above them.
#   security / golem / secretary / admin / hive

var game
var player
var arch: String = "security"
var kind: String = "boss"
var hp: float = 200.0
var max_hp: float = 200.0
var radius: float = 14.0
var touch_dmg: float = 1.0
var hurt_t: float = 0.0
var tele: float = 0.0
var hacked: float = 0.0
var anim: float = 0.0
var t: float = 0.0

var fire_cd: float = 1.5
var move_cd: float = 0.0
var target: Vector2 = Vector2.ZERO
var charge_t: float = 0.0
var shield: float = 0.0
var summon_cd: float = 4.0
var split_left: int = 2
var drones: Array = []

var say_t: float = 0.0
var say_text: String = ""
var quip_cd: float = 6.0
var broke: bool = false

func _lines() -> Array:
	match arch:
		"reaper": return ["КУРЬЕР: доставка смерти. распишись.", "КУРЬЕР: ты не убежишь. я быстрее."]
		"warden": return ["УБОРЩИК: грязь. везде грязь. убрать.", "УБОРЩИК: ты - мусор. цикл очистки."]
		"overseer": return ["НАДЗОР: я вижу каждый твой шаг.", "НАДЗОР: прятаться бесполезно."]
		"security": return ["ОХРАНА: доступ запрещён. применяю силу.", "ОХРАНА: нарушитель. нейтрализовать.", "ОХРАНА: ты не пройдёшь ресепшн."]
		"golem": return ["ГОЛЕМ: бумага... везде бумага... ЗАЖЕВАЛО.", "ГОЛЕМ: подпиши здесь. и здесь. и умри.", "ГОЛЕМ: тонер кончился. как и твоё время."]
		"secretary": return ["СЕКРЕТАРЬ: у вас назначена смерть. без записи не приму.", "СЕКРЕТАРЬ: нас много. очень много.", "СЕКРЕТАРЬ: минуточку... вас разделят."]
		"admin": return ["АДМИН: root-доступ только у меня.", "АДМИН: поднимаю щит. вызываю подмогу.", "АДМИН: ты всего лишь гостевой аккаунт."]
		"hive": return ["РОЙ: мы жужжим как один. ты один.", "РОЙ: нас не убить по частям.", "РОЙ: тысяча глаз смотрит на тебя."]
	return ["..."]

func _say(s: String) -> void:
	say_text = s
	say_t = 3.0
	if game != null and game.audio: game.audio.sfx("blip")

func _ready() -> void:
	target = position
	match arch:
		"security": radius = 13.0
		"reaper": radius = 12.0
		"warden": radius = 15.0
		"overseer": radius = 13.0
		"golem": radius = 15.0
		"secretary": radius = 12.0
		"admin": radius = 15.0
		"hive":
			radius = 16.0
			for i in range(7):
				drones.append(Vector2(cos(TAU*i/7.0), sin(TAU*i/7.0)))
	var ls := _lines()
	_say(ls[0])

func _enraged() -> bool:
	return hp < max_hp * 0.5

func _process(delta: float) -> void:
	if game == null or not game.is_active():
		return
	if player == null or not is_instance_valid(player):
		return
	t += delta; anim += delta
	hurt_t = max(0.0, hurt_t - delta)
	tele = max(0.0, tele - delta)
	fire_cd = max(0.0, fire_cd - delta)
	shield = max(0.0, shield - delta)
	say_t = max(0.0, say_t - delta)
	quip_cd -= delta
	if quip_cd <= 0.0:
		quip_cd = randf_range(7.0, 12.0)
		var ls := _lines()
		_say(ls[randi() % ls.size()])
	var rage := 1.4 if _enraged() else 1.0
	match arch:
		"security": _security(delta, rage)
		"golem": _golem(delta, rage)
		"secretary": _secretary(delta, rage)
		"admin": _admin(delta, rage)
		"hive": _hive(delta, rage)
		"reaper": _reaper(delta, rage)
		"warden": _warden(delta, rage)
		"overseer": _overseer(delta, rage)
	queue_redraw()

func _to() -> Vector2:
	return player.position - position

func _drift(target_pos: Vector2, speed: float, delta: float) -> void:
	var d: Vector2 = (target_pos - position)
	if d.length() > 1.0:
		var step: Vector2 = d.normalized() * speed * delta
		if not _solid(position.x + step.x, position.y): position.x += step.x
		if not _solid(position.x, position.y + step.y): position.y += step.y

func _solid(px: float, py: float) -> bool:
	var TILE: int = game.TILE
	return game.is_solid(int(floor(px / TILE)), int(floor(py / TILE)))

func _clamppos() -> void:
	var W: float = game.COLS * game.TILE
	var H: float = game.ROWS * game.TILE
	position.x = clamp(position.x, radius, W - radius)
	position.y = clamp(position.y, radius, H - radius)

func _wander(delta: float, speed: float) -> void:
	move_cd -= delta
	if move_cd <= 0.0:
		move_cd = 1.5
		var W: float = game.COLS * game.TILE
		var H: float = game.ROWS * game.TILE
		target = Vector2(randf_range(radius + 8, W - radius - 8), randf_range(radius + 8, H * 0.6))
	_drift(target, speed, delta)

func _security(delta: float, rage: float) -> void:
	if charge_t > 0.0:
		charge_t -= delta
		_drift(player.position, 165.0 * rage, delta)
	else:
		_wander(delta, 40.0 * rage)
		if fire_cd <= 0.0 and tele <= 0.0:
			tele = 0.5
		if tele > 0.0 and tele < 0.05:
			fire_cd = 1.6
			var base: Vector2 = _to().normalized()
			for i in range(5):
				var sp := deg_to_rad(-24 + 12 * i)
				game.spawn_bullet(position + base.rotated(sp) * (radius+3), base.rotated(sp), "enemy", 1.0, Color(1.0,0.7,0.2), 100.0, 3.0)
			if game.audio: game.audio.sfx("blip")
			if _to().length() < 130.0 and randf() < 0.5: charge_t = 0.45
	_clamppos()

func _golem(delta: float, rage: float) -> void:
	_wander(delta, 28.0 * rage)
	if fire_cd <= 0.0 and tele <= 0.0:
		tele = 0.5
	if tele > 0.0 and tele < 0.05:
		fire_cd = 1.4
		var d: Vector2 = _to().normalized()
		game.spawn_bullet(position + d * (radius+3), d, "enemy", 2.0, Color(0.9,0.87,0.7), 60.0, 6.0)
		for i in range(7):
			var a := TAU * i / 7.0 + t
			game.spawn_bullet(position + Vector2(cos(a),sin(a))*(radius+2), Vector2(cos(a),sin(a)), "enemy", 1.0, Color(0.7,0.7,0.75), 78.0, 2.0)
		if game.audio: game.audio.sfx("blip")
	_clamppos()

func _secretary(delta: float, rage: float) -> void:
	_drift(player.position, 44.0 * rage, delta)
	if fire_cd <= 0.0 and tele <= 0.0:
		tele = 0.4
	if tele > 0.0 and tele < 0.05:
		fire_cd = 1.2
		var d: Vector2 = _to().normalized()
		for i in range(3):
			var sp := deg_to_rad(-15 + 15 * i)
			game.spawn_bullet(position + d.rotated(sp)*(radius+3), d.rotated(sp), "enemy", 1.0, Color(0.8,0.5,0.9), 95.0, 3.0)
	_clamppos()

func _admin(delta: float, rage: float) -> void:
	_wander(delta, 30.0 * rage)
	summon_cd -= delta
	if summon_cd <= 0.0:
		summon_cd = 6.0
		shield = 2.2
		game.summon_add(position + Vector2(-24, -10), "turret")
		game.summon_add(position + Vector2(24, -10), "turret")
		if game.audio: game.audio.sfx("gate")
	if fire_cd <= 0.0:
		fire_cd = 1.5
		var n := 10
		for i in range(n):
			var a := TAU * i / n + t * 0.5
			game.spawn_bullet(position + Vector2(cos(a),sin(a))*(radius+2), Vector2(cos(a),sin(a)), "enemy", 1.0, Color(0.4,0.7,1.0), 84.0, 3.0)
	_clamppos()

func _hive(delta: float, rage: float) -> void:
	_wander(delta, 46.0 * rage)
	for i in range(drones.size()):
		var a: float = t * 2.0 + TAU * i / drones.size()
		drones[i] = Vector2(cos(a), sin(a)) * (radius + 4.0 + sin(t*3.0+i)*3.0)
	if fire_cd <= 0.0:
		fire_cd = 1.0
		for off in drones:
			var d: Vector2 = (player.position - (position + off)).normalized()
			game.spawn_bullet(position + off, d, "enemy", 1.0, Color(0.9,0.5,0.3), 80.0, 2.0)
	_clamppos()

func hurt(d: float) -> void:
	if shield > 0.0 and arch == "admin":
		d *= 0.25
	hp -= d
	if not broke and hp < max_hp * 0.5 and hp > 0.0:
		broke = true
		game.shake = max(game.shake, 0.6)
		if game.hitstop != null: game.hitstop = max(game.hitstop, 0.08)
		_say("...НЕДОСТАТОЧНО. Я ТОЛЬКО НАЧИНАЮ.")
		if game.audio: game.audio.sfx("glitch")
	hurt_t = 0.07
	if game.audio: game.audio.sfx("bosshit")
	if hp <= 0.0:
		hp = 0.0
		if arch == "secretary" and split_left > 0:
			_split()
			return
		if game.audio: game.audio.sfx("explode")
		game.enemy_killed(self)

func _split() -> void:
	var copies := 2
	for i in range(copies):
		var m = get_script().new()
		m.game = game; m.player = player; m.arch = "secretary"
		m.max_hp = max_hp * 0.4; m.hp = m.max_hp
		m.split_left = split_left - 1
		m.radius = radius * 0.7
		m.position = position + Vector2(randf_range(-14,14), randf_range(-14,14))
		game.enemies.append(m)
		get_parent().add_child(m)
	if game.audio: game.audio.sfx("ehit")
	game.enemy_killed(self)

func hack() -> void:
	hacked = 4.0

func _draw() -> void:
	var _sb: float = abs(sin(t * 3.0)) * 1.5
	draw_circle(Vector2(0, radius*0.8), radius * (1.0 + _sb * 0.04), Color(0,0,0,0.32))
	var _ap: float = 0.5 + 0.5 * sin(t * 2.5)
	var _aura := Color(1.0, 0.3, 0.3, 0.05 + 0.04 * _ap)
	if broke:
		# enraged phase: hotter, bigger, jittering aura + rage spikes
		_aura = Color(1.0, 0.15, 0.1, 0.12 + 0.08 * _ap)
		for _si in range(6):
			var _sa: float = t * 4.0 + _si * 1.05
			var _tip := Vector2(cos(_sa), sin(_sa)) * (radius + 4.0 + _ap * 3.0)
			draw_line(Vector2(cos(_sa), sin(_sa)) * radius * 0.8, _tip, Color(1.0, 0.25, 0.15, 0.6), 1.5)
	draw_circle(Vector2.ZERO, radius + 5.0 + _ap * 3.0, _aura)
	if tele > 0.0:
		draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU * (1.0 - tele/0.5), 24, Color(1.0,0.9,0.3,0.8), 1.5)
	match arch:
		"security": _d_security()
		"golem": _d_golem()
		"secretary": _d_secretary()
		"admin": _d_admin()
		"hive": _d_hive()
		"reaper": _d_reaper()
		"warden": _d_warden()
		"overseer": _d_overseer()
	# living damage detail: sparks + severed cables scale with HP lost
	var _dmgf: float = 1.0 - clamp(hp / max_hp, 0.0, 1.0)
	if _dmgf > 0.12:
		var _ns: int = int(_dmgf * 4.0) + 1
		for _i in range(_ns):
			if int(t * 9.0 + _i * 3) % 4 == 0:
				var _a: float = randf() * TAU
				var _rr: float = radius * (0.4 + randf() * 0.7)
				draw_circle(Vector2(cos(_a), sin(_a)) * _rr, 0.9, Color(1.0, 0.8, 0.3, 0.85))
		if _dmgf > 0.55:
			for _j in range(2):
				var _cx: float = -radius * 0.5 + _j * radius
				var _sw: float = sin(t * 3.0 + _j * 2.0) * 2.2
				draw_line(Vector2(_cx, radius * 0.4), Vector2(_cx + _sw, radius * 0.95), Color(0.5, 0.05, 0.1), 1.3)
	var frac: float = clamp(hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(-radius, -radius - 6, radius*2, 2), Color(0,0,0,0.6))
	draw_rect(Rect2(-radius, -radius - 6, radius*2*frac, 2), Color(1.0,0.4,0.4))
	if say_t > 0.0 and say_text != "":
		var tw: float = say_text.length() * 4.2 + 8.0
		var bx: float = clamp(position.x - tw*0.5, 2.0, game.COLS*game.TILE - tw - 2.0) - position.x
		var by: float = -radius - 18.0
		draw_rect(Rect2(bx, by, tw, 11), Color(0.1,0.03,0.05,0.92))
		draw_rect(Rect2(bx, by, tw, 1), Color(1.0,0.5,0.4,0.8))
		draw_string(game.font, Vector2(bx+4, by+8), say_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1.0,0.8,0.75))

func _flash() -> bool: return hurt_t > 0.0
func _eye() -> Vector2: return _to().normalized()

func _d_security() -> void:
	var c := Color(0.3,0.4,0.7)
	if charge_t > 0.0: c = Color(1.0,0.5,0.3)
	if _flash(): c = Color(1,1,1)
	var r := radius
	var bob := sin(t * 3.0) * 0.8
	draw_rect(Rect2(-r, -r + bob, r*2, r*2), c.darkened(0.25))
	draw_rect(Rect2(-r+1, -r+1 + bob, r*2-2, r*2-2), c)
	draw_rect(Rect2(-r+1, -r+1 + bob, r*2-2, 3), c.lightened(0.35))
	draw_rect(Rect2(-r+1, r-3 + bob, r*2-2, 2), c.darkened(0.4))
	var sh := sin(t * 2.0) * 1.0
	draw_rect(Rect2(-r-2, -r+2+sh + bob, 3, 6), c.darkened(0.15))
	draw_rect(Rect2(r-1, -r+2-sh + bob, 3, 6), c.darkened(0.15))
	for i in range(4):
		draw_rect(Rect2(-r+2 + i*4, -1 + bob, 2, 3), Color(0.95,0.85,0.2) if i%2==0 else Color(0.15,0.12,0.1))
	var ec := Color(1.0,0.3,0.2)
	if charge_t > 0.0: ec = Color(1.0,0.85,0.3)
	draw_rect(Rect2(_eye().x*3-4, -3 + bob, 8, 3), Color(0.08,0.03,0.03))
	draw_rect(Rect2(_eye().x*3-3, -2.5 + bob, 6, 2), ec)
	var strobe := int(t * 6.0) % 2 == 0
	draw_circle(Vector2(-4, -r-3 + bob), 1.6, Color(1.0,0.2,0.2, 1.0 if strobe else 0.3))
	draw_circle(Vector2(4, -r-3 + bob), 1.6, Color(0.2,0.4,1.0, 0.3 if strobe else 1.0))

func _d_golem() -> void:
	var c := Color(0.85,0.82,0.68)
	if _flash(): c = Color(1,1,1)
	var r := radius
	for i in range(5):
		var sa := t * 1.2 + i * 1.3
		var sr := r + 4.0 + sin(t * 2.0 + i) * 3.0
		var sp := Vector2(cos(sa), sin(sa)) * sr
		draw_rect(Rect2(sp.x - 2, sp.y - 2.5, 4, 5), Color(0.9, 0.88, 0.78, 0.5))
	var pts := PackedVector2Array()
	for i in range(14):
		var a := TAU*i/14.0
		var rr: float = r * (0.78 + 0.30*abs(sin(i*2.1 + t*1.5)))
		pts.append(Vector2(cos(a),sin(a))*rr)
	draw_colored_polygon(pts, c.darkened(0.12))
	var pts2 := PackedVector2Array()
	for i in range(14):
		var a2 := TAU*i/14.0
		var rr2: float = r * (0.6 + 0.22*abs(sin(i*1.7 + t)))
		pts2.append(Vector2(cos(a2),sin(a2))*rr2)
	draw_colored_polygon(pts2, c)
	draw_line(Vector2(-r*0.5,-r*0.3), Vector2(r*0.4,r*0.2), c.darkened(0.25), 1.0)
	draw_line(Vector2(r*0.4,-r*0.4), Vector2(-r*0.3,r*0.4), c.darkened(0.2), 1.0)
	draw_circle(Vector2(-3,-2), 2.4, Color(0.12,0.10,0.18))
	draw_circle(Vector2(3,-2), 2.4, Color(0.12,0.10,0.18))
	draw_circle(Vector2(-3,-2)+_eye()*0.8, 1.1, Color(1.0,0.35,0.2))
	draw_circle(Vector2(3,-2)+_eye()*0.8, 1.1, Color(1.0,0.35,0.2))
	draw_rect(Rect2(-5, 3, 10, 2), Color(0.18,0.13,0.22))
	var drip := fmod(t * 1.5, 1.0)
	draw_circle(Vector2(sin(t)*3.0, 5.0 + drip * 5.0), 1.0, Color(0.15,0.1,0.2, 1.0 - drip))

func _d_secretary() -> void:
	var c := Color(0.7,0.5,0.85)
	if _flash(): c = Color(1,1,1)
	var r := radius
	# nested matryoshka shells that rattle apart, more when enraged
	var sep: float = (0.9 if broke else 0.25) * abs(sin(t * 3.0))
	for i in range(3):
		var rr: float = r * (1.0 - i * 0.24)
		var oy: float = -i * sep * r * 0.18
		var cc: Color = c.darkened(i * 0.12) if i % 2 == 0 else c.lightened(0.1)
		draw_circle(Vector2(0, 1 + oy), rr, cc.darkened(0.28))
		draw_circle(Vector2(0, oy), rr * 0.94, cc)
		draw_line(Vector2(-rr * 0.72, 1 + oy), Vector2(rr * 0.72, 1 + oy), c.darkened(0.35), 1.0)
	# painted dress band + buttons
	draw_rect(Rect2(-r * 0.7, r * 0.3, r * 1.4, r * 0.55), c.darkened(0.24))
	for k in range(3):
		draw_circle(Vector2(-r * 0.4 + k * r * 0.4, r * 0.55), 1.3, Color(0.96, 0.82, 0.42, 0.9))
	# headscarf peak
	draw_circle(Vector2(0, -r * 0.55), r * 0.5, c.lightened(0.18))
	draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.5, -r * 0.5), Vector2(0, -r * 1.15), Vector2(r * 0.5, -r * 0.5)]), c.darkened(0.12))
	# tracking eyes + occasional blink
	var e := _eye()
	var eh: float = 0.4 if int(t * 1.3) % 7 == 0 else 1.4
	draw_circle(Vector2(-2.4, -r * 0.5) + e * 0.7, eh, Color(0.1, 0.05, 0.12))
	draw_circle(Vector2(2.4, -r * 0.5) + e * 0.7, eh, Color(0.1, 0.05, 0.12))
	draw_rect(Rect2(-2, -r * 0.5 + 3, 4, 1), Color(0.9, 0.3, 0.4))
	# spinning appointment-stamp arm (faster when enraged)
	var sa: float = t * (5.5 if broke else 2.2)
	var sp: Vector2 = Vector2(cos(sa), sin(sa)) * (r + 5.0)
	draw_line(Vector2.ZERO, sp, c.darkened(0.2), 2.0)
	draw_rect(Rect2(sp.x - 2.0, sp.y - 2.0, 4.0, 4.0), Color(0.85, 0.2, 0.3))

func _d_admin() -> void:
	var c := Color(0.25,0.5,0.85)
	if _flash(): c = Color(1,1,1)
	var r := radius
	# server tower body with beveled edges
	draw_rect(Rect2(-r, -r, r * 2, r * 2), c.darkened(0.12))
	draw_rect(Rect2(-r, -r, r * 2, 3), c.lightened(0.3))
	draw_rect(Rect2(-r, r - 3, r * 2, 2), c.darkened(0.35))
	draw_rect(Rect2(-r, -r, 3, r * 2), c.darkened(0.25))
	draw_rect(Rect2(r - 3, -r, 3, r * 2), c.darkened(0.25))
	# rack rows with live blinking LEDs
	for i in range(4):
		draw_rect(Rect2(-r + 3, -r + 4 + i * 5, r * 2 - 6, 2.4), Color(0.06, 0.14, 0.3))
		for j in range(5):
			var on: bool = (int(t * 4.0) + i * 3 + j) % 3 == 0
			var lc: Color = Color(0.4, 1.0, 0.6) if (i + j) % 2 == 0 else Color(1.0, 0.7, 0.3)
			draw_rect(Rect2(-r + 5 + j * 4, -r + 4.2 + i * 5, 2, 2), Color(lc.r, lc.g, lc.b, 0.95 if on else 0.2))
	# central lens/eye that tracks you
	draw_circle(Vector2.ZERO, r * 0.5, Color(0.05, 0.12, 0.28))
	draw_circle(Vector2.ZERO, r * 0.42, Color(0.1, 0.24, 0.46))
	draw_circle(_eye() * r * 0.26, r * 0.2, Color(0.4, 0.9, 1.0))
	draw_circle(_eye() * r * 0.26, r * 0.09, Color(0.9, 1.0, 1.0))
	# slow scanning beam
	var ba: float = t * 1.5
	draw_line(Vector2.ZERO, Vector2(cos(ba), sin(ba)) * (r + 9.0), Color(0.4, 0.8, 1.0, 0.22), 1.0)
	if shield > 0.0:
		var pulse: float = 0.5 + 0.5 * sin(t * 10.0)
		draw_arc(Vector2.ZERO, r + 5.0, 0.0, TAU, 28, Color(0.4, 0.8, 1.0, 0.4 + 0.4 * pulse), 2.0)
		for k in range(6):
			var ka: float = TAU * k / 6.0 + t
			draw_circle(Vector2(cos(ka), sin(ka)) * (r + 5.0), 1.4, Color(0.6, 0.95, 1.0, 0.6 + 0.4 * pulse))

func _d_hive() -> void:
	var qp := 0.5 + 0.5 * sin(t * 4.0)
	draw_circle(Vector2.ZERO, radius*0.75, Color(0.35,0.16,0.10,0.6))
	draw_circle(Vector2.ZERO, radius*0.5, Color(0.6,0.28,0.15, 0.5 + 0.3*qp))
	draw_circle(Vector2.ZERO, radius*0.25, Color(1.0,0.7,0.35, qp))
	for oi in range(drones.size()):
		var off = drones[oi]
		var dc := Color(0.9,0.5,0.3)
		if _flash(): dc = Color(1,1,1)
		var w: float = 2.5 + abs(sin(anim*26.0 + oi))*2.5
		draw_circle(off - Vector2(w,0), 1.6, Color(0.8,0.8,0.9,0.3))
		draw_circle(off + Vector2(w,0), 1.6, Color(0.8,0.8,0.9,0.3))
		draw_circle(off, 3.5, dc)
		draw_circle(off, 2.0, Color(0.4,0.15,0.1))
		draw_rect(Rect2(off.x - 2.0, off.y - 0.5, 4.0, 1.0), Color(0.95,0.8,0.3,0.7))
		draw_circle(off + _eye()*1.0, 1.0, Color(1.0,0.9,0.4))

func _reaper(delta: float, rage: float) -> void:
	if charge_t > 0.0:
		charge_t -= delta
		_drift(player.position, 190.0 * rage, delta)
	else:
		_wander(delta, 58.0 * rage)
		if fire_cd <= 0.0:
			fire_cd = 1.2
			var d: Vector2 = _to().normalized()
			for i in range(2):
				var sp := deg_to_rad(-10.0 + 20.0 * i)
				game.spawn_bullet(position + d.rotated(sp) * (radius + 3.0), d.rotated(sp), "enemy", 1.0, Color(0.7, 0.3, 0.9), 130.0, 3.0)
			if _to().length() < 150.0 and randf() < 0.6: charge_t = 0.4
	_clamppos()

func _warden(delta: float, rage: float) -> void:
	_wander(delta, 24.0 * rage)
	if fire_cd <= 0.0:
		fire_cd = 1.3
		var n := 12
		for i in range(n):
			var a := TAU * i / n + t * 1.2
			var dd := Vector2(cos(a), sin(a))
			game.spawn_bullet(position + dd * (radius + 2.0), dd, "enemy", 1.0, Color(0.4, 0.9, 0.8), 76.0, 2.5)
	_clamppos()

func _overseer(delta: float, rage: float) -> void:
	summon_cd -= delta
	if summon_cd <= 0.0:
		summon_cd = 3.4
		var W: float = game.COLS * game.TILE
		var H: float = game.ROWS * game.TILE
		position = Vector2(randf_range(radius + 8.0, W - radius - 8.0), randf_range(radius + 8.0, H * 0.5))
		shield = 0.3
		if game.audio: game.audio.sfx("glitch")
	if fire_cd <= 0.0 and tele <= 0.0:
		tele = 0.45
	if tele > 0.0 and tele < 0.05:
		fire_cd = 0.9 / rage
		var d: Vector2 = _to().normalized()
		game.spawn_bullet(position + d * (radius + 3.0), d, "enemy", 1.0, Color(1.0, 0.4, 0.4), 170.0, 3.0)
	_clamppos()

func _d_reaper() -> void:
	var c := Color(0.45, 0.18, 0.6)
	if charge_t > 0.0: c = Color(0.9, 0.4, 1.0)
	if _flash(): c = Color(1, 1, 1)
	var r := radius
	draw_colored_polygon(PackedVector2Array([Vector2(0, -r), Vector2(r * 0.8, 0), Vector2(0, r), Vector2(-r * 0.8, 0)]), c)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -r * 0.6), Vector2(r * 0.4, 0), Vector2(0, r * 0.5), Vector2(-r * 0.4, 0)]), c.lightened(0.2))
	for s in [-1, 1]:
		var a: float = t * 3.0 * float(s)
		var tip := Vector2(cos(a), sin(a)) * (r + 6.0)
		draw_line(Vector2.ZERO, tip, Color(0.8, 0.85, 0.9), 1.5)
		draw_circle(tip, 1.8, Color(1.0, 0.6, 1.0))
	draw_circle(_eye() * r * 0.3, 2.2, Color(1.0, 0.4, 0.5))

func _d_warden() -> void:
	var c := Color(0.16, 0.55, 0.5)
	if _flash(): c = Color(1, 1, 1)
	var r := radius
	draw_circle(Vector2.ZERO, r, c)
	for i in range(6):
		var a := TAU * i / 6.0 + t * 1.5
		var d := Vector2(cos(a), sin(a))
		draw_line(d * r * 0.5, d * (r + 5.0), c.lightened(0.25), 2.0)
		draw_circle(d * (r + 5.0), 1.6, Color(0.5, 1.0, 0.9))
	draw_circle(Vector2.ZERO, r * 0.45, Color(0.05, 0.2, 0.2))
	draw_circle(_eye() * r * 0.25, 2.4, Color(0.5, 1.0, 0.9))

func _d_overseer() -> void:
	var c := Color(0.5, 0.12, 0.14)
	if _flash(): c = Color(1, 1, 1)
	var r := radius
	if shield > 0.0:
		draw_circle(Vector2.ZERO, r + 3.0, Color(1.0, 0.3, 0.3, 0.4))
	draw_circle(Vector2.ZERO, r, c)
	draw_circle(Vector2.ZERO, r * 0.7, c.darkened(0.2))
	draw_circle(Vector2.ZERO, r * 0.55, Color(0.9, 0.9, 0.95))
	draw_circle(_eye() * r * 0.3, r * 0.28, Color(0.7, 0.1, 0.1))
	draw_circle(_eye() * r * 0.3, r * 0.12, Color(0.1, 0.0, 0.0))
	if tele > 0.0:
		draw_line(Vector2.ZERO, _eye() * (r + 18.0), Color(1.0, 0.3, 0.3, 0.5), 1.0)
