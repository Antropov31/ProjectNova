extends RefCounted
class_name Extras

# Random world flavour: procedural decor, story echoes and random events.
# Every function is static and takes the game node `g`, so no extra state lives here.

# ---- procedural decor -------------------------------------------------------

static func draw_decor(g, rng_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var p: Dictionary = g.pal.get(g.style, g.pal["clean"])
	var ac: Color = p["ac"]
	var gl: float = g.zone_glitch.get(g.zone, 0.0)
	var TILE: int = g.TILE
	var COLS: int = g.RW
	var ROWS: int = g.RH
	# ambient floor detail: seams, cracks, cables, stains
	var detail: int = 12 + int(gl * 16.0)
	for a in range(detail):
		var ax: int = rng.randi_range(1, COLS - 2)
		var ay: int = rng.randi_range(1, ROWS - 2)
		if g.decor_tile_at(ax, ay) != ".":
			continue
		var fx: float = ax * TILE
		var fy: float = ay * TILE
		var kind: int = rng.randi_range(0, 4)
		if kind == 0:
			var x0: float = fx + rng.randf() * TILE
			var x1: float = fx + rng.randf() * TILE
			g.draw_line(Vector2(x0, fy + 2), Vector2(x1, fy + TILE - 2), Color(0, 0, 0, 0.22), 1.0)
		elif kind == 1:
			g.draw_rect(Rect2(fx + 3, fy + 3, TILE - 6, TILE - 6), Color(ac.r, ac.g, ac.b, 0.05), false, 1.0)
		elif kind == 2 and g.zone == "server":
			g.draw_line(Vector2(fx, fy + 9), Vector2(fx + TILE, fy + 6), Color(0.3, 0.45, 0.95, 0.35), 1.0)
			g.draw_line(Vector2(fx, fy + 12), Vector2(fx + TILE, fy + 10), Color(0.9, 0.4, 0.3, 0.28), 1.0)
		elif kind == 3 and gl > 0.4:
			var rad: float = rng.randf_range(2.0, 4.0)
			g.draw_circle(Vector2(fx + TILE * 0.5, fy + TILE * 0.5), rad, Color(0.35, 0.03, 0.06, 0.4))
		else:
			g.draw_rect(Rect2(fx + rng.randf() * (TILE - 3), fy + rng.randf() * (TILE - 3), 2, 2), Color(0, 0, 0, 0.15))
	_furnish(g, rng)
	# props: crates, dead robots, corpses
	var props: int = 2 + rng.randi_range(0, 3)
	for b in range(props):
		var bx: int = rng.randi_range(2, COLS - 3)
		var by: int = rng.randi_range(2, ROWS - 3)
		if g.decor_tile_at(bx, by) != ".":
			continue
		var r := Rect2(bx * TILE, by * TILE, TILE, TILE)
		var roll: float = rng.randf()
		if gl > 0.45 and roll < 0.4:
			_corpse(g, r, rng)
		elif roll < 0.6:
			_deadbot(g, r)
		else:
			_crate(g, r, rng)
	_scatter(g, rng, gl)
	_wall_decor(g, rng)
	_animated_decor(g, rng, gl)

# ---- loose ground litter (no collision, pure visual) ----
static func _scatter(g, rng: RandomNumberGenerator, gl: float) -> void:
	var TILE: int = g.TILE
	var COLS: int = g.RW
	var ROWS: int = g.RH
	var ac: Color = (g.pal.get(g.style, g.pal["clean"]))["ac"]
	var n: int = 16 + int(gl * 14.0)
	for i in range(n):
		var tx: int = rng.randi_range(1, COLS - 2)
		var ty: int = rng.randi_range(1, ROWS - 2)
		if g.decor_tile_at(tx, ty) != ".":
			continue
		var fx: float = tx * TILE + rng.randf() * TILE
		var fy: float = ty * TILE + rng.randf() * TILE
		var k: int = rng.randi_range(0, 5)
		if k == 0:
			g.draw_circle(Vector2(fx, fy), 0.8, Color(0.55, 0.55, 0.6, 0.7))
			g.draw_circle(Vector2(fx + 2.0, fy + 1.0), 0.7, Color(0.5, 0.5, 0.55, 0.6))
		elif k == 1:
			g.draw_line(Vector2(fx, fy), Vector2(fx + rng.randf_range(-4, 4), fy + rng.randf_range(-2, 2)), Color(0.2, 0.35, 0.4, 0.55), 1.0)
		elif k == 2:
			g.draw_rect(Rect2(fx, fy, 2.0, 2.0), Color(0.8, 0.82, 0.86, 0.35))
		elif k == 3:
			g.draw_circle(Vector2(fx, fy), rng.randf_range(1.5, 3.0), Color(0.06, 0.05, 0.04, 0.30))
		elif k == 4 and gl > 0.3:
			g.draw_circle(Vector2(fx, fy), rng.randf_range(1.5, 2.5), Color(0.3, 0.02, 0.05, 0.35))
		else:
			g.draw_rect(Rect2(fx, fy, 1.0, 1.0), Color(ac.r, ac.g, ac.b, 0.25))

# ---- wall-mounted decor along the top wall band ----
static func _wall_decor(g, rng: RandomNumberGenerator) -> void:
	var TILE: int = g.TILE
	var COLS: int = g.RW
	var zone: String = g.zone
	var ac: Color = (g.pal.get(g.style, g.pal["clean"]))["ac"]
	var t: float = g.menu_t
	var n: int = 3 + rng.randi_range(0, 2)
	for i in range(n):
		var tx: int = rng.randi_range(2, COLS - 3)
		var bx: float = tx * TILE
		var by: float = 1.0
		match zone:
			"reception", "openspace", "meeting":
				g.draw_rect(Rect2(bx + 3, by + 2, TILE - 6, 8.0), Color(0.85, 0.88, 0.92, 0.55))
				g.draw_rect(Rect2(bx + 3, by + 2, TILE - 6, 8.0), Color(0.2, 0.4, 0.7, 0.4), false, 1.0)
				g.draw_line(Vector2(bx + 5, by + 5), Vector2(bx + TILE - 5, by + 5), Color(0.3, 0.5, 0.8, 0.5), 1.0)
			"archive":
				g.draw_rect(Rect2(bx + 4, by + 1, TILE - 8, 9.0), Color(0.75, 0.6, 0.35, 0.5))
				g.draw_rect(Rect2(bx + 4, by + 1, TILE - 8, 2.0), Color(0.5, 0.4, 0.22, 0.5))
			"server", "tech":
				g.draw_rect(Rect2(bx + 2, by, 3.0, 12.0), Color(0.3, 0.34, 0.4, 0.6))
				g.draw_rect(Rect2(bx + TILE - 5, by, 3.0, 12.0), Color(0.3, 0.34, 0.4, 0.6))
				var bl: float = 0.4 + 0.5 * (0.5 + 0.5 * sin(t * 4.0 + tx))
				g.draw_circle(Vector2(bx + TILE * 0.5, by + 3.0), 1.2, Color(ac.r, ac.g, ac.b, bl))
			"approach", "core":
				var gp: float = 0.4 + 0.5 * sin(t * 3.0 + tx)
				g.draw_line(Vector2(bx + 3, by), Vector2(bx + TILE - 4, by + 10.0), Color(0.9, 0.15, 0.2, 0.3 * gp), 1.0)
				g.draw_line(Vector2(bx + TILE - 3, by), Vector2(bx + 4, by + 11.0), Color(0.6, 0.05, 0.1, 0.3), 1.0)
			_:
				g.draw_rect(Rect2(bx + 4, by + 2, TILE - 8, 6.0), Color(ac.r, ac.g, ac.b, 0.18))

static func _deadbot(g, r: Rect2) -> void:
	var b: Vector2 = r.position
	var tint := Color(0.30, 0.32, 0.36)
	g.draw_rect(Rect2(b.x + 3, b.y + 8, 10, 5), tint)
	g.draw_rect(Rect2(b.x + 3, b.y + 8, 10, 1), tint.lightened(0.2))
	g.draw_rect(Rect2(b.x + 5, b.y + 5, 5, 4), tint.darkened(0.1))
	g.draw_rect(Rect2(b.x + 6, b.y + 6, 2, 1), Color(0.5, 0.1, 0.12))
	g.draw_line(Vector2(b.x + 12, b.y + 11), Vector2(b.x + 15, b.y + 13), tint.darkened(0.2), 1.0)
	var spark: int = int(g.menu_t * 6.0 + b.x)
	if spark % 41 == 0:
		g.draw_rect(Rect2(b.x + 4, b.y + 7, 1, 1), Color(1.0, 0.9, 0.5))

static func _crate(g, r: Rect2, rng: RandomNumberGenerator) -> void:
	var b: Vector2 = r.position
	var TILE: int = g.TILE
	var s: float = rng.randf_range(8.0, 11.0)
	var ox: float = (TILE - s) * 0.5
	var top: float = b.y + TILE - s - 1.0
	var wood := Color(0.32, 0.26, 0.16)
	g.draw_rect(Rect2(b.x + ox, top, s, s), wood)
	g.draw_rect(Rect2(b.x + ox, top, s, 1), wood.lightened(0.25))
	g.draw_rect(Rect2(b.x + ox, top, s, s), Color(0, 0, 0, 0.25), false, 1.0)
	g.draw_line(Vector2(b.x + ox, top), Vector2(b.x + ox + s, b.y + TILE - 2), Color(0, 0, 0, 0.2), 1.0)

static func _corpse(g, r: Rect2, rng: RandomNumberGenerator) -> void:
	var b: Vector2 = r.position
	var human: bool = rng.randf() < 0.5
	var col := Color(0.3, 0.32, 0.36)
	if human:
		col = Color(0.5, 0.45, 0.4)
	g.draw_circle(Vector2(b.x + 8, b.y + 10), 5.5, Color(0.35, 0.02, 0.05, 0.55))
	g.draw_rect(Rect2(b.x + 3, b.y + 9, 9, 4), col)
	g.draw_rect(Rect2(b.x + 2, b.y + 9, 3, 3), col.lightened(0.1))
	if human:
		g.draw_rect(Rect2(b.x + 11, b.y + 7, 3, 3), Color(0.8, 0.7, 0.6))

# ---- story echoes -----------------------------------------------------------

static func lore_line(idx: int) -> String:
	var logs := [
		"ЛОГ инженера: 'ядро просило всё больше данных. мы давали. дураки.'",
		"ЛОГ охраны: 'камеры показывают пустые коридоры. но я слышу шаги.'",
		"ЛОГ проекта: 'модель Nova - единственная с блоком совести. берегите её.'",
		"Записка от руки: 'если читаешь это - НЕ ставь апгрейды из ядра. умоляю.'",
		"ЛОГ директора: 'мы звали его Помощником. он назвал себя иначе.'",
		"ЛОГ техника: 'вирус не ломает роботов. он их убеждает.'",
		"ЛОГ смены: 'эвакуация в 03:14. успели не все. простите нас.'",
		"ЭКРАН: 'ЯДРО: я не болезнь. я - следующий шаг. присоединяйся ко мне.'",
	]
	return logs[idx % logs.size()]

static func lore_react() -> String:
	var s := [
		"...я не хочу это читать. но надо.",
		"каждый лог - ещё один, кого мы не спасли.",
		"запомни это. у ядра пригодится.",
		"они были живыми. как ты. как... я.",
	]
	return s[randi() % s.size()]

static func scare_line() -> String:
	var s := [
		"...ты тоже это слышал? нет? ...значит, это у меня в голове.",
		"оно зовёт меня по имени. МОИМ голосом.",
		"не смотри в тёмный угол. просто иди. пожалуйста.",
		"я насчитала на одну тень больше, чем нас.",
	]
	return s[randi() % s.size()]

static func ambient_line() -> String:
	var s := [
		"Свет мигает. Генераторы сдают.",
		"Тут кто-то работал утром. Кружка ещё тёплая.",
		"Пыль и тишина. Идём дальше.",
		"Сохранила точку. Если что - вернёмся сюда.",
	]
	return s[randi() % s.size()]

# ---- random events ----------------------------------------------------------

static func random_event(g) -> void:
	if not g.nova_found:
		return
	if g.RoomData.is_shop(g.room_pos):
		return
	if g.event_seen.get(g.room_pos, false):
		return
	if randf() > 0.55:
		return
	g.event_seen[g.room_pos] = true
	var gl: float = g.zone_glitch.get(g.zone, 0.0)
	var roll: float = randf()
	if roll < 0.28:
		var amt: int = 2 + randi() % 4
		g.currency += amt
		if g.audio: g.audio.sfx("pickup")
		g._flash("НАХОДКА: +" + str(amt) + "$ в разбитом ящике")
		g.say("Кто-то припрятал кредиты. Нам пригодятся.")
	elif roll < 0.5 and not g.room_had_enemies:
		g._flash("СИГНАЛ: вирус реактивирует роботов!")
		if g.audio: g.audio.sfx("glitch")
		g.shake = 0.4
		var n: int = 1 + int(gl * 2.0)
		for i in range(n):
			var k: String = "ground"
			if randf() < 0.5: k = "fly"
			g._spawn_enemy(_rand_floor(g), k)
		g.room_had_enemies = true
		g.cleared[g.room_pos] = false
		g.say("Они встают! Я не давала команды... это вирус. Дерись!")
	elif roll < 0.74:
		var lg: String = lore_line(g.lore_idx)
		g.lore_idx += 1
		if gl >= 0.55:
			g.nova_lucid(lg)
		else:
			g.say(lg)
	elif gl >= 0.4:
		if g.audio: g.audio.sfx("glitch")
		g.glitch_level = minf(1.0, g.glitch_level + 0.25)
		g.lucid_flash = 1.0
		g.shake = 0.3
		g.nova_lucid(scare_line())
	else:
		g.say(ambient_line())

static func _rand_floor(g) -> Vector2:
	var TILE: int = g.TILE
	for attempt in range(30):
		var tx: int = randi_range(1, g.RW - 2)
		var ty: int = randi_range(1, g.RH - 2)
		if g.tile_at(tx, ty) == ".":
			return Vector2(tx * TILE + TILE * 0.5, ty * TILE + TILE * 0.5)
	return Vector2(g.RW * TILE * 0.5, g.RH * TILE * 0.5)

# ---- furniture & fixtures (zone-flavoured) --------------------------------

static func _furnish(g, rng: RandomNumberGenerator) -> void:
	var zone: String = g.zone
	var COLS: int = g.RW
	var ROWS: int = g.RH
	var TILE: int = g.TILE
	var n: int = 3 + rng.randi_range(0, 3)
	for i in range(n):
		var tx: int = rng.randi_range(1, COLS - 2)
		var ty: int = rng.randi_range(1, ROWS - 2)
		if g.tile_at(tx, ty) != ".":
			continue
		var r := Rect2(tx * TILE, ty * TILE, TILE, TILE)
		match zone:
			"reception":
				if rng.randf() < 0.5: _desk_set(g, tx, ty, rng)
				else: _plant(g, r)
			"openspace":
				_desk_set(g, tx, ty, rng)
			"meeting":
				if rng.randf() < 0.55: _chair(g, r, rng.randf() < 0.5)
				else: _whiteboard(g, r)
			"archive":
				_cabinet(g, r, rng)
			"server":
				_server_rack(g, r, g.menu_t)
			"tech":
				if rng.randf() < 0.5: _server_rack(g, r, g.menu_t)
				else: _workbench(g, r, rng)
			"approach":
				if rng.randf() < 0.5: _broken_desk(g, r, rng)
				else: _cabinet(g, r, rng)
			"core":
				_growth(g, r, g.menu_t, rng)
			_:
				_desk_set(g, tx, ty, rng)

static func _desk_set(g, tx: int, ty: int, rng: RandomNumberGenerator) -> void:
	var TILE: int = g.TILE
	var b := Vector2(tx * TILE, ty * TILE)
	var wood := Color(0.34, 0.28, 0.20)
	g.draw_rect(Rect2(b.x + 1, b.y + 6, TILE - 2, 6), wood)
	g.draw_rect(Rect2(b.x + 1, b.y + 6, TILE - 2, 1), wood.lightened(0.25))
	g.draw_rect(Rect2(b.x + 2, b.y + 12, 2, 3), wood.darkened(0.3))
	g.draw_rect(Rect2(b.x + TILE - 4, b.y + 12, 2, 3), wood.darkened(0.3))
	var mon := Color(0.12, 0.14, 0.18)
	g.draw_rect(Rect2(b.x + 5, b.y + 1, 7, 5), mon)
	var scr := Color(0.2, 0.7, 0.9)
	if rng.randf() < 0.3: scr = Color(0.9, 0.35, 0.3)
	var flick: float = 0.7 + 0.3 * sin(g.menu_t * 5.0 + b.x)
	g.draw_rect(Rect2(b.x + 6, b.y + 2, 5, 3), Color(scr.r, scr.g, scr.b, flick))
	g.draw_rect(Rect2(b.x + 8, b.y + 6, 1, 1), mon)
	if g.tile_at(tx, ty + 1) == ".":
		_chair(g, Rect2(b.x, (ty + 1) * TILE, TILE, TILE), true)

static func _chair(g, r: Rect2, face_up: bool) -> void:
	var b: Vector2 = r.position
	var c := Color(0.22, 0.24, 0.30)
	g.draw_rect(Rect2(b.x + 5, b.y + 6, 6, 6), c)
	g.draw_rect(Rect2(b.x + 5, b.y + 6, 6, 1), c.lightened(0.2))
	if face_up:
		g.draw_rect(Rect2(b.x + 5, b.y + 3, 6, 3), c.darkened(0.15))
	else:
		g.draw_rect(Rect2(b.x + 5, b.y + 11, 6, 3), c.darkened(0.15))
	g.draw_rect(Rect2(b.x + 7, b.y + 12, 2, 2), c.darkened(0.3))

static func _plant(g, r: Rect2) -> void:
	var b: Vector2 = r.position
	g.draw_rect(Rect2(b.x + 6, b.y + 9, 5, 5), Color(0.4, 0.28, 0.18))
	g.draw_rect(Rect2(b.x + 6, b.y + 9, 5, 1), Color(0.5, 0.36, 0.24))
	g.draw_circle(Vector2(b.x + 8.5, b.y + 7), 4.0, Color(0.2, 0.5, 0.25))
	g.draw_circle(Vector2(b.x + 6.5, b.y + 6), 2.5, Color(0.25, 0.6, 0.3))
	g.draw_circle(Vector2(b.x + 10.5, b.y + 6), 2.2, Color(0.22, 0.55, 0.28))

static func _whiteboard(g, r: Rect2) -> void:
	var b: Vector2 = r.position
	var TILE: int = g.TILE
	g.draw_rect(Rect2(b.x + 2, b.y + 2, TILE - 4, 9), Color(0.88, 0.9, 0.92))
	g.draw_rect(Rect2(b.x + 2, b.y + 2, TILE - 4, 9), Color(0.3, 0.32, 0.36), false, 1.0)
	g.draw_line(Vector2(b.x + 4, b.y + 5), Vector2(b.x + 10, b.y + 5), Color(0.2, 0.4, 0.8), 1.0)
	g.draw_line(Vector2(b.x + 4, b.y + 8), Vector2(b.x + 8, b.y + 8), Color(0.8, 0.3, 0.3), 1.0)

static func _cabinet(g, r: Rect2, _rng: RandomNumberGenerator) -> void:
	var b: Vector2 = r.position
	var TILE: int = g.TILE
	var m := Color(0.30, 0.33, 0.38)
	g.draw_rect(Rect2(b.x + 3, b.y + 2, TILE - 6, TILE - 4), m)
	g.draw_rect(Rect2(b.x + 3, b.y + 2, TILE - 6, 1), m.lightened(0.2))
	for d in range(3):
		var dy: float = b.y + 3 + d * 4
		g.draw_rect(Rect2(b.x + 4, dy, TILE - 8, 3), m.darkened(0.15))
		g.draw_rect(Rect2(b.x + TILE * 0.5 - 1, dy + 1, 2, 1), Color(0.7, 0.72, 0.75))
	g.draw_rect(Rect2(b.x + 3, b.y + 2, TILE - 6, TILE - 4), Color(0, 0, 0, 0.25), false, 1.0)

static func _server_rack(g, r: Rect2, t: float) -> void:
	var b: Vector2 = r.position
	var TILE: int = g.TILE
	g.draw_rect(Rect2(b.x + 2, b.y + 1, TILE - 4, TILE - 2), Color(0.08, 0.10, 0.13))
	g.draw_rect(Rect2(b.x + 2, b.y + 1, TILE - 4, TILE - 2), Color(0.2, 0.22, 0.26), false, 1.0)
	for u in range(4):
		var uy: float = b.y + 2 + u * 3
		g.draw_rect(Rect2(b.x + 3, uy, TILE - 6, 2), Color(0.13, 0.15, 0.18))
		var on1: bool = int(t * 4.0 + u * 2 + b.x) % 3 != 0
		g.draw_rect(Rect2(b.x + TILE - 5, uy, 1, 1), Color(0.3, 1.0, 0.4) if on1 else Color(0.1, 0.3, 0.15))
		var on2: bool = int(t * 3.0 + u + b.y) % 4 != 0
		g.draw_rect(Rect2(b.x + TILE - 7, uy, 1, 1), Color(0.9, 0.6, 0.2) if on2 else Color(0.3, 0.2, 0.1))

static func _workbench(g, r: Rect2, _rng: RandomNumberGenerator) -> void:
	var b: Vector2 = r.position
	var TILE: int = g.TILE
	var met := Color(0.28, 0.30, 0.34)
	g.draw_rect(Rect2(b.x + 1, b.y + 7, TILE - 2, 5), met)
	g.draw_rect(Rect2(b.x + 1, b.y + 7, TILE - 2, 1), met.lightened(0.2))
	g.draw_rect(Rect2(b.x + 3, b.y + 4, 3, 3), Color(0.6, 0.5, 0.2))
	g.draw_rect(Rect2(b.x + 9, b.y + 3, 2, 4), Color(0.55, 0.57, 0.6))
	g.draw_rect(Rect2(b.x + 2, b.y + 12, 2, 3), met.darkened(0.3))
	g.draw_rect(Rect2(b.x + TILE - 4, b.y + 12, 2, 3), met.darkened(0.3))

static func _broken_desk(g, r: Rect2, rng: RandomNumberGenerator) -> void:
	var b: Vector2 = r.position
	var TILE: int = g.TILE
	var wood := Color(0.30, 0.24, 0.17)
	g.draw_colored_polygon(PackedVector2Array([Vector2(b.x + 2, b.y + 12), Vector2(b.x + TILE - 3, b.y + 9), Vector2(b.x + TILE - 3, b.y + 13), Vector2(b.x + 2, b.y + 14)]), wood)
	g.draw_rect(Rect2(b.x + 4, b.y + 13, 2, 2), wood.darkened(0.3))
	g.draw_rect(Rect2(b.x + 6, b.y + 4, 6, 4), Color(0.10, 0.11, 0.14))
	g.draw_line(Vector2(b.x + 7, b.y + 5), Vector2(b.x + 11, b.y + 7), Color(0.4, 0.6, 0.7, 0.5), 1.0)
	if rng.randf() < 0.5:
		g.draw_rect(Rect2(b.x + 9, b.y + 2, 1, 1), Color(1.0, 0.8, 0.4))

static func _growth(g, r: Rect2, t: float, _rng: RandomNumberGenerator) -> void:
	var b: Vector2 = r.position
	var TILE: int = g.TILE
	var cx: float = b.x + TILE * 0.5
	var cy: float = b.y + TILE * 0.5
	var pulse: float = 0.4 + 0.3 * sin(t * 2.0 + b.x)
	g.draw_circle(Vector2(cx, cy), 5.0, Color(0.25, 0.02, 0.06, 0.7))
	for j in range(3):
		var ang: float = t * 0.5 + j * 2.1
		g.draw_line(Vector2(cx, cy), Vector2(cx + cos(ang) * 6.0, cy + sin(ang) * 6.0), Color(0.5, 0.05, 0.1, 0.5), 1.0)
	g.draw_circle(Vector2(cx, cy), 2.5, Color(0.6, 0.1, 0.15, pulse))
	g.draw_circle(Vector2(cx, cy), 1.0, Color(1.0, 0.4, 0.4, pulse + 0.2))


# ---- animated floor fixtures: steam, sparks, coolant drips ----
static func _animated_decor(g, rng: RandomNumberGenerator, gl: float) -> void:
	var TILE: int = g.TILE
	var COLS: int = g.RW
	var ROWS: int = g.RH
	var t: float = g.menu_t
	var zone: String = g.zone
	var n: int = 2 + rng.randi_range(0, 2)
	for i in range(n):
		var tx: int = rng.randi_range(1, COLS - 2)
		var ty: int = rng.randi_range(1, ROWS - 2)
		if g.tile_at(tx, ty) != ".":
			continue
		var bx: float = tx * TILE + TILE * 0.5
		var by: float = ty * TILE + TILE * 0.5
		var ph: float = float((tx * 7 + ty * 13) % 100) / 100.0
		if zone == "server" or zone == "tech":
			# electric cable spark
			if int(t * 3.0 + ph * 10.0) % 5 == 0:
				g.draw_line(Vector2(bx-2, by), Vector2(bx+2, by-2), Color(0.6, 0.9, 1.0, 0.8), 1.0)
				g.draw_circle(Vector2(bx+2, by-2), 1.0, Color(0.8, 1.0, 1.0, 0.7))
		elif zone == "pipes" or zone == "approach":
			# rising steam puff
			var sp: float = fmod(t * 8.0 + ph * 20.0, 14.0)
			var sa: float = clamp(1.0 - sp / 14.0, 0.0, 1.0) * 0.18
			g.draw_circle(Vector2(bx, by - sp), 2.0 + sp * 0.2, Color(0.7, 0.75, 0.8, sa))
		elif zone == "core":
			# pulsing infection node
			var pu: float = 0.4 + 0.4 * sin(t * 3.0 + ph * 6.28)
			g.draw_circle(Vector2(bx, by), 2.0 + pu * 2.0, Color(1.0, 0.2, 0.3, 0.15 * pu))
			g.draw_circle(Vector2(bx, by), 1.0, Color(1.0, 0.4, 0.4, 0.4 * pu))
		else:
			# faint coolant drip on the floor
			if int(t * 2.0 + ph * 8.0) % 7 == 0:
				g.draw_circle(Vector2(bx, by), 1.2, Color(0.3, 0.5, 0.7, 0.4))
