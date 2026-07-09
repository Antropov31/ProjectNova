extends RefCounted
class_name RoomData

# 8 zones, 31 rooms. Main corridor along y=0 with branches at y=-1.
# Every grid is guaranteed 12 rows x 22 cols (game also normalizes on load).
#
# Legend:
#   #  wall   .  floor   ^  spike   L  laser   w  breakable wall (shoot to open)
#   o  barrel(explodes)  =  table cover   *  lamp (light source)
#   y  target  g  barrier  K  keycard  k  keycard-door  T  terminal
#   +  health  M  heart container   $  shop pedestal
#   e ground  f swarm  s turret  u hunter  z elite   b miniboss   B core
#   J spread  X dash  H hack  C blast   1 shotgun  2 rail

static func _blank() -> Array:
	var g: Array = []
	for y in range(12):
		var row := ""
		for x in range(22):
			row += ("#" if (y==0 or y==11 or x==0 or x==21) else ".")
		g.append(row)
	return g

static func _blank_sized(w: int, h: int) -> Array:
	var g: Array = []
	for y in range(h):
		var row := ""
		for x in range(w):
			row += ("#" if (y==0 or y==h-1 or x==0 or x==w-1) else ".")
		g.append(row)
	return g

static func _round_corners(g: Array, rad: int) -> void:
	var h: int = g.size()
	if h == 0: return
	var w: int = String(g[0]).length()
	for y in range(h):
		for x in range(w):
			var corners = [[0,0],[w-1,0],[0,h-1],[w-1,h-1]]
			for cxy in corners:
				var dx: int = x - cxy[0]
				var dy: int = y - cxy[1]
				if dx*dx + dy*dy > rad*rad and ((cxy[0]==0 and x<rad) or (cxy[0]==w-1 and x>w-1-rad)) and ((cxy[1]==0 and y<rad) or (cxy[1]==h-1 and y>h-1-rad)):
					_put(g, x, y, "#")

static func _put(g: Array, x: int, y: int, ch: String) -> void:
	if y < 0 or y >= g.size(): return
	var row: String = g[y]
	if x < 0 or x >= row.length(): return
	g[y] = row.substr(0, x) + ch + row.substr(x + 1)

static func _rect(g: Array, x0: int, y0: int, x1: int, y1: int, ch: String) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_put(g, x, y, ch)

static func all() -> Dictionary:
	var r: Dictionary = {}

	# ============ ZONE 1: РЕСЕПШН (clean) ============
	var a := _blank()  # 1.1 вход (tutorial)
	_put(a, 3, 3, "T"); _put(a, 2, 2, "*"); _put(a, 19, 2, "*")
	_rect(a, 9, 5, 12, 6, "="); _put(a, 16, 8, "e")
	r[Vector2i(0,0)] = {"grid": a, "style": "clean"}

	var a2 := _blank()  # 1.2 лаунж (branch up)
	_put(a2, 10, 5, "M"); _put(a2, 4, 4, "="); _put(a2, 16, 7, "=")
	_put(a2, 3, 2, "*"); _put(a2, 18, 2, "*"); _put(a2, 6, 8, "e")
	r[Vector2i(0,-1)] = {"grid": a2, "style": "clean"}

	var a3 := _blank()  # 1.3 турникеты
	_rect(a3, 7, 3, 7, 8, "="); _rect(a3, 14, 3, 14, 8, "=")
	_put(a3, 5, 5, "e"); _put(a3, 16, 6, "e"); _put(a3, 10, 4, "s"); _put(a3, 2, 2, "*")
	r[Vector2i(1,0)] = {"grid": a3, "style": "clean"}

	var a4 := _blank()  # 1.4 miniboss Бот-Секьюрити
	_put(a4, 10, 4, "b"); _put(a4, 3, 3, "o"); _put(a4, 18, 3, "o"); _put(a4, 10, 8, "X")
	_put(a4, 2, 2, "*"); _put(a4, 19, 2, "*")
	r[Vector2i(2,0)] = {"grid": a4, "style": "clean"}

	# ============ ZONE 2: ОПЕНСПЕЙС (office) ============
	var b1 := _blank()  # 2.1 встреча с Nova
	_put(b1, 5, 5, "="); _put(b1, 15, 6, "="); _put(b1, 3, 2, "*"); _put(b1, 18, 2, "*")
	r[Vector2i(3,0)] = {"grid": b1, "style": "office"}

	var b2 := _blank()  # 2.2 ряды столов + breakable up to secret
	_rect(b2, 4, 4, 5, 4, "="); _rect(b2, 9, 6, 10, 6, "="); _rect(b2, 15, 4, 16, 4, "=")
	_put(b2, 6, 3, "s"); _put(b2, 17, 7, "e"); _put(b2, 12, 8, "u")
	_rect(b2, 9, 1, 12, 1, "w")  # breakable wall hiding upward passage
	_put(b2, 3, 2, "*")
	r[Vector2i(4,0)] = {"grid": b2, "style": "office"}

	var b3 := _blank()  # 2.3 кофе-пойнт (secret up, tough)
	_put(b3, 5, 4, "z"); _put(b3, 15, 6, "u"); _put(b3, 10, 5, "C"); _put(b3, 10, 8, "+")
	_put(b3, 3, 3, "="); _put(b3, 17, 3, "="); _put(b3, 10, 2, "*")
	r[Vector2i(4,-1)] = {"grid": b3, "style": "office"}

	var b4 := _blank()  # 2.4 кухня/кафетерий - ШОП №1 (safe)
	_put(b4, 6, 5, "$"); _put(b4, 10, 5, "$"); _put(b4, 14, 5, "$")
	_rect(b4, 4, 7, 17, 7, "="); _put(b4, 3, 2, "*"); _put(b4, 10, 2, "*"); _put(b4, 18, 2, "*")
	r[Vector2i(5,0)] = {"grid": b4, "style": "shop"}

	var b5 := _blank()  # 2.5 boss Принтер-Голем
	_put(b5, 10, 4, "b"); _put(b5, 4, 8, "o"); _put(b5, 16, 8, "o"); _put(b5, 3, 2, "*"); _put(b5, 18, 2, "*")
	r[Vector2i(6,0)] = {"grid": b5, "style": "office"}

	# ============ ZONE 3: ПЕРЕГОВОРНЫЕ (glass) ============
	var c1 := _blank()  # 3.1 стеклянный зал (cover)
	_rect(c1, 6, 3, 6, 8, "="); _rect(c1, 15, 3, 15, 8, "="); _rect(c1, 10, 5, 11, 6, "=")
	_put(c1, 4, 5, "u"); _put(c1, 17, 6, "s"); _put(c1, 10, 2, "*")
	r[Vector2i(7,0)] = {"grid": c1, "style": "glass"}

	var c2 := _blank()  # 3.2 проекционная (пазл: targets -> barrier -> key)
	_put(c2, 2, 3, "T"); _rect(c2, 15, 1, 15, 10, "g"); _put(c2, 18, 5, "K")
	_put(c2, 4, 2, "y"); _put(c2, 6, 8, "y"); _put(c2, 11, 4, "y"); _put(c2, 9, 6, "=")
	_put(c2, 3, 2, "*")
	r[Vector2i(8,0)] = {"grid": c2, "style": "glass"}

	var c3 := _blank()  # 3.3 секретная переговорная (locked, up)
	_put(c3, 10, 5, "M"); _put(c3, 4, 3, "T"); _put(c3, 16, 7, "="); _put(c3, 10, 2, "*")
	r[Vector2i(8,-1)] = {"grid": c3, "style": "glass"}

	var c4 := _blank()  # 3.4 boss Секретарь-Матрёшка
	_put(c4, 10, 4, "b"); _put(c4, 3, 2, "*"); _put(c4, 18, 2, "*")
	r[Vector2i(9,0)] = {"grid": c4, "style": "glass"}

	# ============ ZONE 4: АРХИВ (archive) ============
	var d1 := _blank()  # 4.1 лабиринт стеллажей
	_rect(d1, 4, 1, 4, 7, "#"); _rect(d1, 8, 4, 8, 10, "#"); _rect(d1, 12, 1, 12, 7, "#"); _rect(d1, 16, 4, 16, 10, "#")
	_put(d1, 6, 8, "e"); _put(d1, 14, 3, "u"); _put(d1, 18, 8, "e"); _put(d1, 2, 2, "*")
	r[Vector2i(10,0)] = {"grid": d1, "style": "archive"}

	var d2 := _blank()  # 4.2 хранилище ключа
	_put(d2, 10, 5, "K"); _put(d2, 5, 4, "s"); _put(d2, 15, 4, "s"); _put(d2, 10, 8, "z")
	_rect(d2, 8, 3, 8, 8, "="); _rect(d2, 13, 3, 13, 8, "="); _put(d2, 3, 2, "*")
	r[Vector2i(11,0)] = {"grid": d2, "style": "archive"}

	var d3 := _blank()  # 4.3 секретный архив (breakable up)
	_put(d3, 10, 5, "H"); _put(d3, 5, 7, "="); _put(d3, 15, 7, "="); _put(d3, 10, 2, "*")
	r[Vector2i(11,-1)] = {"grid": d3, "style": "archive"}

	var d4 := _blank()  # 4.4 ШОП №2
	_put(d4, 7, 5, "$"); _put(d4, 11, 5, "$"); _put(d4, 15, 5, "$")
	_rect(d4, 4, 8, 17, 8, "="); _put(d4, 3, 2, "*"); _put(d4, 18, 2, "*")
	r[Vector2i(12,0)] = {"grid": d4, "style": "shop"}

	# ============ ZONE 5: СЕРВЕРНАЯ (server) ============
	var e1 := _blank()  # 5.1 вход по ключ-карте
	_rect(e1, 6, 3, 6, 8, "k")  # keycard gate wall
	_put(e1, 12, 5, "e"); _put(e1, 16, 6, "u"); _put(e1, 3, 2, "*")
	r[Vector2i(13,0)] = {"grid": e1, "style": "server"}

	var e2 := _blank()  # 5.2 дата-центр (взлом H)
	_put(e2, 10, 4, "H"); _rect(e2, 5, 3, 5, 8, "#"); _rect(e2, 16, 3, 16, 8, "#")
	_put(e2, 8, 7, "s"); _put(e2, 13, 7, "s"); _put(e2, 10, 2, "*")
	r[Vector2i(14,0)] = {"grid": e2, "style": "server"}

	var e3 := _blank()  # 5.3 охлаждение (hazard, up)
	_rect(e3, 8, 5, 13, 5, "L"); _put(e3, 5, 8, "^"); _put(e3, 16, 8, "^"); _put(e3, 10, 3, "M")
	_put(e3, 10, 2, "*")
	r[Vector2i(14,-1)] = {"grid": e3, "style": "server"}

	var e4 := _blank()  # 5.5 boss Администратор
	_put(e4, 10, 4, "b"); _put(e4, 3, 2, "*"); _put(e4, 18, 2, "*")
	r[Vector2i(15,0)] = {"grid": e4, "style": "server"}

	var e5 := _blank()  # 5.4 секретный сервер (breakable up from boss room)
	_put(e5, 10, 5, "2"); _put(e5, 6, 4, "$"); _put(e5, 14, 4, "$"); _put(e5, 10, 2, "*")
	r[Vector2i(15,-1)] = {"grid": e5, "style": "server"}

	# ============ ZONE 6: ТЕХЭТАЖ (pipes) ============
	var f1 := _blank()  # 6.1 вентиляция (hazard)
	_rect(f1, 6, 4, 6, 8, "L"); _rect(f1, 14, 4, 14, 8, "L"); _put(f1, 10, 8, "^"); _put(f1, 10, 3, "^")
	_put(f1, 4, 6, "f"); _put(f1, 17, 6, "f"); _put(f1, 10, 2, "*")
	r[Vector2i(16,0)] = {"grid": f1, "style": "pipes"}

	var f2 := _blank()  # 6.2 пробитые кабели (рой)
	_put(f2, 5, 4, "f"); _put(f2, 15, 4, "f"); _put(f2, 5, 8, "f"); _put(f2, 15, 8, "f"); _put(f2, 10, 5, "u"); _put(f2, 10, 8, "p")
	_rect(f2, 9, 1, 12, 1, "w"); _put(f2, 3, 2, "*")
	r[Vector2i(17,0)] = {"grid": f2, "style": "pipes"}

	var f3 := _blank()  # 6.3 магистраль (secret, laser timing)
	_rect(f3, 7, 1, 7, 10, "L"); _rect(f3, 13, 1, 13, 10, "L"); _put(f3, 18, 5, "C"); _put(f3, 10, 2, "*")
	r[Vector2i(17,-1)] = {"grid": f3, "style": "pipes"}

	var f4 := _blank()  # 6.4 boss Рой-Улей
	_put(f4, 10, 4, "b"); _put(f4, 3, 2, "*"); _put(f4, 18, 2, "*")
	r[Vector2i(18,0)] = {"grid": f4, "style": "pipes"}

	# ============ ZONE 7: ПОДСТУП К ЯДРУ (approach) ============
	var g1 := _blank()  # 7.1 зал ожидания (гаунтлет)
	_put(g1, 5, 4, "e"); _put(g1, 15, 4, "u"); _put(g1, 10, 7, "s"); _put(g1, 8, 3, "f"); _put(g1, 12, 8, "e"); _put(g1, 3, 6, "q"); _put(g1, 18, 6, "r")
	_put(g1, 10, 2, "*")
	r[Vector2i(19,0)] = {"grid": g1, "style": "approach"}

	var g2 := _blank()  # 7.2 кабинет директора (secret up, lore)
	_put(g2, 10, 5, "M"); _put(g2, 4, 3, "T"); _rect(g2, 14, 6, 16, 7, "="); _put(g2, 10, 2, "*")
	r[Vector2i(19,-1)] = {"grid": g2, "style": "approach"}

	var g3 := _blank()  # 7.3 последний магазин
	_put(g3, 7, 5, "$"); _put(g3, 11, 5, "$"); _put(g3, 15, 5, "$"); _put(g3, 10, 2, "*"); _put(g3, 3, 2, "*")
	r[Vector2i(20,0)] = {"grid": g3, "style": "shop"}

	var g4 := _blank()  # 7.4 шлюз к ядру (терминал, точка невозврата)
	_put(g4, 10, 5, "T"); _rect(g4, 6, 3, 6, 8, "#"); _rect(g4, 15, 3, 15, 8, "#"); _put(g4, 10, 2, "*")
	r[Vector2i(21,0)] = {"grid": g4, "style": "approach"}

	# ============ ZONE 8: ЯДРО (core) ============
	var core := _blank()
	_rect(core, 2, 3, 3, 8, "#"); _rect(core, 18, 3, 19, 8, "#"); _put(core, 10, 4, "B")
	r[Vector2i(22,0)] = {"grid": core, "style": "core"}

	return r

static func zone_of(pos: Vector2i) -> String:
	var x: int = pos.x
	if x <= 2: return "reception"
	if x <= 6: return "openspace"
	if x <= 9: return "meeting"
	if x <= 12: return "archive"
	if x <= 15: return "server"
	if x <= 18: return "tech"
	if x <= 21: return "approach"
	return "core"

static func boss_arch(pos: Vector2i) -> String:
	match pos:
		Vector2i(2,0): return "security"
		Vector2i(6,0): return "golem"
		Vector2i(9,0): return "secretary"
		Vector2i(15,0): return "admin"
		Vector2i(18,0): return "hive"
	return "security"

# shop room? (safe, no enemies, has pedestals)
static func is_shop(pos: Vector2i) -> bool:
	return pos == Vector2i(5,0) or pos == Vector2i(12,0) or pos == Vector2i(20,0)

# rooms that meet-Nova / are pure story
static func meet_nova(pos: Vector2i) -> bool:
	return pos == Vector2i(3,0)

static func chapter_map(chapter: int, seedv: int) -> Dictionary:
	if chapter <= 1:
		return _gen_ch1(seedv)
	return _gen(chapter, seedv)

# item 4: avoid handing out the same miniboss/boss archetype twice in a row.
static func _pick_arch(rng: RandomNumberGenerator, arches: Array, last: String) -> String:
	var a: String = String(arches[rng.randi() % arches.size()])
	if a == last and arches.size() > 1:
		a = String(arches[(arches.find(a) + 1 + rng.randi() % (arches.size() - 1)) % arches.size()])
	return a

static func _gen(chapter: int, seedv: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seedv + chapter * 100003
	var r: Dictionary = {}
	var final_core: bool = chapter >= 3
	var zseq: Array = (["server", "tech", "approach"] if chapter == 2 else ["tech", "approach", "core"])
	var style_of: Dictionary = {"server": "server", "tech": "pipes", "approach": "approach", "core": "core", "clean": "clean"}
	var arches: Array = ["security", "golem", "secretary", "admin", "hive", "reaper", "warden", "overseer"]
	var dirs: Array = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	var _apool: Array = arches.duplicate()
	for _i in range(_apool.size() - 1, 0, -1):
		var _j: int = rng.randi() % (_i + 1)
		var _t = _apool[_i]; _apool[_i] = _apool[_j]; _apool[_j] = _t
	var mini_arch: String = String(_apool[0])
	var boss_arch2: String = String(_apool[1])

	# ---- 1. grow a branching graph of rooms in all 4 directions (Isaac / Soul Knight style) ----
	var occupied: Dictionary = {Vector2i(0,0): true}
	var cells: Array = [Vector2i(0,0)]
	var target: int = 13 + chapter * 2 + rng.randi() % 3
	var guard: int = 0
	while cells.size() < target and guard < 5000:
		guard += 1
		var base: Vector2i = cells[rng.randi() % cells.size()]
		var dd: Array = dirs.duplicate()
		for di in range(dd.size() - 1, 0, -1):
			var dj: int = rng.randi() % (di + 1)
			var dt = dd[di]; dd[di] = dd[dj]; dd[dj] = dt
		for d in dd:
			var np: Vector2i = base + d
			if occupied.has(np):
				continue
			var ncount: int = 0
			for d2 in dirs:
				if occupied.has(np + d2):
					ncount += 1
			# keep it mostly tree-shaped (attach at a single neighbour),
			# but allow the occasional loop so the map is not a pure tree
			if ncount == 1 or (ncount == 2 and rng.randf() < 0.18):
				occupied[np] = true
				cells.append(np)
				break

	# ---- 2. BFS distance from the start room (drives zone gradient + boss placement) ----
	var dist: Dictionary = {Vector2i(0,0): 0}
	var q: Array = [Vector2i(0,0)]
	var head: int = 0
	while head < q.size():
		var cur: Vector2i = q[head]; head += 1
		for d in dirs:
			var nb: Vector2i = cur + d
			if occupied.has(nb) and not dist.has(nb):
				dist[nb] = int(dist[cur]) + 1
				q.append(nb)
	var maxd: int = 1
	for k in dist.keys():
		maxd = max(maxd, int(dist[k]))

	# ---- 3. pick special rooms; boss sits at the farthest node so the player must explore ----
	var boss_cell: Vector2i = Vector2i(0,0)
	var best: int = -1
	for c in cells:
		if int(dist.get(c, 0)) > best:
			best = int(dist.get(c, 0)); boss_cell = c
	var rest: Array = []
	for c in cells:
		if c != Vector2i(0,0) and c != boss_cell:
			rest.append(c)
	for ri in range(rest.size() - 1, 0, -1):
		var rj: int = rng.randi() % (ri + 1)
		var rt = rest[ri]; rest[ri] = rest[rj]; rest[rj] = rt
	var special: Dictionary = {}
	var far_sorted: Array = rest.duplicate()
	far_sorted.sort_custom(func(x, y): return int(dist.get(x, 0)) > int(dist.get(y, 0)))
	if far_sorted.size() > 0:
		special[far_sorted[0]] = "miniboss"
	var want: Array = ["shop", "shop", "treasure", "secret", "lore"]
	var wi: int = 0
	for c in rest:
		if special.has(c):
			continue
		if wi >= want.size():
			break
		special[c] = str(want[wi]); wi += 1

	# ---- 4. build the actual room metas ----
	for c in cells:
		var frac: float = float(dist.get(c, 0)) / float(maxd)
		var zi: int = clampi(int(frac * 2.999), 0, 2)
		var zn: String = str(zseq[zi])
		var meta: Dictionary = {}
		if c == Vector2i(0,0):
			var g: Array = _blank()
			_put(g, 3, 2, "*"); _put(g, 10, 2, "*"); _put(g, 18, 2, "*")
			_put(g, 6, 5, "$"); _put(g, 10, 5, "$"); _put(g, 14, 5, "$")
			_put(g, 8, 8, "+"); _put(g, 12, 8, "+")
			_rect(g, 4, 7, 17, 7, "=")
			meta = {"grid": g, "zone": zn, "style": "shop", "shop": true, "hub": true}
		elif c == boss_cell:
			if final_core:
				var g: Array = _blank_sized(34, 20)
				_round_corners(g, 6)
				_put(g, 17, 5, "B")
				_put(g, 3, 3, "*"); _put(g, 30, 3, "*"); _put(g, 3, 16, "*"); _put(g, 30, 16, "*")
				meta = {"grid": g, "zone": "core", "style": "core", "zoom": 0.72}
			else:
				var g: Array = _blank_sized(28, 18)
				_round_corners(g, 4)
				_put(g, 14, 6, "b")
				_put(g, 5, 12, "o"); _put(g, 22, 12, "o")
				_put(g, 14, 13, "V")
				_put(g, 3, 3, "*"); _put(g, 24, 3, "*")
				meta = {"grid": g, "zone": zn, "style": str(style_of.get(zn, "server")), "zoom": 0.85}
				meta["boss"] = boss_arch2; meta["descent"] = true
		else:
			var kind: String = str(special.get(c, ""))
			if kind == "miniboss":
				var g: Array = _blank_sized(28, 18)
				_round_corners(g, 4)
				_put(g, 14, 6, "b")
				_put(g, 4, 4, "o"); _put(g, 23, 4, "o")
				_put(g, 3, 3, "*"); _put(g, 24, 3, "*")
				meta = {"grid": g, "zone": zn, "style": str(style_of.get(zn, "server")), "zoom": 0.9}
				meta["boss"] = mini_arch
			elif kind == "shop":
				var g: Array = _blank()
				_put(g, 6, 5, "$"); _put(g, 10, 5, "$"); _put(g, 14, 5, "$")
				_rect(g, 4, 7, 17, 7, "=")
				_put(g, 3, 2, "*"); _put(g, 10, 2, "*"); _put(g, 18, 2, "*")
				meta = {"grid": g, "zone": zn, "style": "shop", "shop": true}
			elif kind == "treasure":
				var g: Array = _blank()
				_put(g, 10, 5, "M")
				var lets: Array = ["J", "X", "H", "C"]
				_put(g, 13, 5, str(lets[rng.randi() % lets.size()]))
				_put(g, 7, 5, "z"); _put(g, 4, 8, "o")
				_put(g, 10, 2, "*")
				meta = {"grid": g, "zone": zn, "style": str(style_of.get(zn, "server"))}
			elif kind == "secret":
				var g: Array = _blank()
				_put(g, 10, 5, "T"); _put(g, 6, 6, "+"); _put(g, 14, 6, "+"); _put(g, 10, 8, "M")
				_put(g, 4, 2, "*"); _put(g, 16, 2, "*")
				meta = {"grid": g, "zone": zn, "style": "clean", "easter": true}
			elif kind == "lore":
				var g: Array = _blank()
				_put(g, 10, 5, "T"); _put(g, 5, 7, "+"); _put(g, 15, 7, "+")
				_put(g, 10, 2, "*")
				meta = {"grid": g, "zone": zn, "style": str(style_of.get(zn, "server"))}
			else:
				var _opt = [[22,12,1.4],[28,14,1.2],[24,18,1.15],[32,12,1.15],[26,16,1.2]][rng.randi() % 5]
				var g: Array = _blank_sized(_opt[0], _opt[1])
				if rng.randf() < 0.3:
					_round_corners(g, 4 + rng.randi() % 3)
				_gen_room(g, rng, zn, frac)
				meta = {"grid": g, "zone": zn, "style": str(style_of.get(zn, "server")), "zoom": _opt[2]}
				if rng.randf() < 0.16 and zn != "core":
					meta["dark"] = true
		r[c] = meta
	return r

static func _gen_room(g: Array, rng: RandomNumberGenerator, zn: String, frac: float) -> void:
	_put(g, 3, 2, "*"); _put(g, 18, 2, "*")
	# occasional coolant/water pool (walkable, reflective) in wet zones
	if (zn == "tech" or zn == "server" or zn == "pipes" or zn == "approach") and rng.randf() < 0.4:
		var wx0: int = 4 + rng.randi() % 8
		var wy0: int = 6 + rng.randi() % 3
		for _wy in range(wy0, min(wy0 + 2, 10)):
			for _wx in range(wx0, min(wx0 + 3 + rng.randi() % 2, 20)):
				if String(g[_wy]).substr(_wx, 1) == ".":
					_put(g, _wx, _wy, "~")
	# item 6: rare hand-built set-pieces; item 1: puzzle variant
	if rng.randf() < 0.12:
		_setpiece_room(g, rng, zn, frac)
		return
	if rng.randf() < 0.25:
		_puzzle_room(g, rng)
		return
	var layout: int = rng.randi() % 8
	match layout:
		0:
			_rect(g, 6, 3, 6, 8, "="); _rect(g, 15, 3, 15, 8, "=")
		1:
			_rect(g, 9, 5, 12, 6, "="); _put(g, 5, 4, "="); _put(g, 16, 7, "=")
		2:
			_rect(g, 5, 4, 5, 8, "#"); _rect(g, 16, 4, 16, 8, "#")
		3:
			_put(g, 8, 4, "o"); _put(g, 13, 8, "o"); _rect(g, 10, 3, 11, 3, "=")
		4:
			_rect(g, 10, 3, 11, 4, "#"); _rect(g, 10, 7, 11, 8, "#"); _put(g, 6, 5, "="); _put(g, 15, 5, "=")
		5:
			_rect(g, 4, 3, 5, 3, "="); _rect(g, 16, 3, 17, 3, "="); _rect(g, 4, 8, 5, 8, "="); _rect(g, 16, 8, 17, 8, "=")
		6:
			_put(g, 5, 3, "o"); _put(g, 9, 5, "o"); _put(g, 13, 7, "o"); _put(g, 17, 9, "o"); _rect(g, 7, 6, 14, 6, "=")
		_:
			_rect(g, 3, 4, 9, 4, "="); _rect(g, 12, 7, 18, 7, "=")
	if zn == "tech" or zn == "approach" or zn == "core":
		if rng.randf() < 0.5:
			_rect(g, 8, 5, 13, 5, "L")
		if rng.randf() < 0.4:
			_put(g, 5, 8, "^"); _put(g, 16, 8, "^")
	var pool: Array = ["e", "f", "s"]
	if frac > 0.35: pool.append("u")
	if frac > 0.4: pool.append("p")
	if frac > 0.5: pool.append("q")
	if frac > 0.55: pool.append("r")
	if frac > 0.6: pool.append("z")
	var count: int = 5 + int(frac * 4.0) + rng.randi() % 3
	for i in range(count):
		var ex: int = 3 + rng.randi() % 16
		var ey: int = 2 + rng.randi() % 8
		if String(g[ey]).substr(ex, 1) == ".":
			_put(g, ex, ey, str(pool[rng.randi() % pool.size()]))
	# item 1: hidden stash sealed behind a breakable wall, else a plain medkit
	if rng.randf() < 0.35:
		var sx: int = (4 + rng.randi() % 4) if rng.randf() < 0.5 else (14 + rng.randi() % 4)
		_put(g, sx, 1, ("M" if rng.randf() < 0.35 else "+"))
		_put(g, sx - 1, 1, "#"); _put(g, sx + 1, 1, "#")
		_put(g, sx, 2, "w")
	elif rng.randf() < 0.3:
		_put(g, 10, 9, ("!" if rng.randf() < 0.22 else "+"))
	if rng.randf() < 0.08:
		_put(g, 3, 9, "W")

static func _puzzle_room(g: Array, rng: RandomNumberGenerator) -> void:
	var spots: Array = [Vector2i(4,4), Vector2i(8,8), Vector2i(14,3), Vector2i(6,3), Vector2i(15,8), Vector2i(9,9)]
	for i in range(spots.size() - 1, 0, -1):
		var j: int = rng.randi() % (i + 1)
		var tmp = spots[i]; spots[i] = spots[j]; spots[j] = tmp
	var n: int = 2 + rng.randi() % 2
	for i in range(n):
		var s: Vector2i = spots[i]
		_put(g, s.x, s.y, "y")
	_put(g, 20, 1, ("M" if rng.randf() < 0.5 else "C"))
	_put(g, 19, 1, "g"); _put(g, 20, 2, "g")

static func _setpiece_room(g: Array, rng: RandomNumberGenerator, zn: String, frac: float) -> void:
	if rng.randf() < 0.5:
		var pts: Array = [Vector2i(4,3), Vector2i(8,3), Vector2i(12,3), Vector2i(16,3), Vector2i(6,8), Vector2i(14,8)]
		for p in pts:
			_put(g, p.x, p.y, "f")
		_put(g, 10, 6, "u")
		_put(g, 10, 9, "+")
	else:
		_rect(g, 7, 1, 7, 10, "L"); _rect(g, 13, 1, 13, 10, "L")
		_put(g, 5, 8, "^"); _put(g, 15, 3, "^")
		_put(g, 18, 5, ("C" if frac > 0.5 else "+"))
		_put(g, 3, 5, "e")


static func _gen_ch1(seedv: int) -> Dictionary:
	# Chapter 1 opens with a FIXED three-room story intro that never changes:
	#   room 1 (0,0) spawn/tutorial   room 2 (1,0) first enemies   room 3 (2,0) meet Nova.
	# The rest of the floor (shops, secrets, miniboss and finally the boss + elevator)
	# grows ONLY out of the Nova room, so the boss/descent can never be reached
	# without first finding Nova. That keeps the story and perks from breaking.
	var rng := RandomNumberGenerator.new()
	rng.seed = seedv + 777013
	var r: Dictionary = {}
	var zseq: Array = ["reception", "openspace", "meeting", "archive"]
	var style_of: Dictionary = {"reception": "clean", "openspace": "office", "meeting": "glass", "archive": "archive"}
	var arches: Array = ["security", "golem", "secretary", "hive"]
	var dirs: Array = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]

	var SPAWN: Vector2i = Vector2i(0, 0)
	var ENEMY: Vector2i = Vector2i(1, 0)
	var NOVA: Vector2i = Vector2i(2, 0)

	var occupied: Dictionary = {SPAWN: true, ENEMY: true, NOVA: true}
	var cells: Array = [NOVA]
	var target: int = 14 + rng.randi() % 3
	var guard: int = 0
	while cells.size() < target and guard < 5000:
		guard += 1
		var base: Vector2i = cells[rng.randi() % cells.size()]
		var dd: Array = dirs.duplicate()
		for di in range(dd.size() - 1, 0, -1):
			var dj: int = rng.randi() % (di + 1)
			var dt = dd[di]; dd[di] = dd[dj]; dd[dj] = dt
		for d in dd:
			var np: Vector2i = base + d
			if np.x <= 1:
				continue
			if occupied.has(np):
				continue
			var ncount: int = 0
			for d2 in dirs:
				var nn: Vector2i = np + d2
				if occupied.has(nn) and nn.x >= 2:
					ncount += 1
			if ncount == 1 or (ncount == 2 and rng.randf() < 0.16):
				occupied[np] = true
				cells.append(np)
				break

	var dist: Dictionary = {SPAWN: 0}
	var q: Array = [SPAWN]
	var head: int = 0
	while head < q.size():
		var cur: Vector2i = q[head]; head += 1
		for d in dirs:
			var nb: Vector2i = cur + d
			if occupied.has(nb) and not dist.has(nb):
				dist[nb] = int(dist[cur]) + 1
				q.append(nb)
	var maxd: int = 1
	for k in dist.keys():
		maxd = max(maxd, int(dist[k]))

	var boss_cell: Vector2i = NOVA
	var best: int = -1
	for c in cells:
		if c == NOVA:
			continue
		if int(dist.get(c, 0)) > best:
			best = int(dist.get(c, 0)); boss_cell = c
	if boss_cell == NOVA:
		boss_cell = Vector2i(3, 0)
		occupied[boss_cell] = true
		cells.append(boss_cell)
		dist[boss_cell] = 1

	var rest: Array = []
	for c in cells:
		if c != NOVA and c != boss_cell:
			rest.append(c)
	for ri in range(rest.size() - 1, 0, -1):
		var rj: int = rng.randi() % (ri + 1)
		var rt = rest[ri]; rest[ri] = rest[rj]; rest[rj] = rt
	var special: Dictionary = {}
	var far_sorted: Array = rest.duplicate()
	far_sorted.sort_custom(func(x, y): return int(dist.get(x, 0)) > int(dist.get(y, 0)))
	if far_sorted.size() > 0:
		special[far_sorted[0]] = "miniboss"
	var want: Array = ["shop", "lore", "shop", "treasure", "secret", "lore"]
	var wi: int = 0
	for c in rest:
		if special.has(c):
			continue
		if wi >= want.size():
			break
		special[c] = str(want[wi]); wi += 1

	var lore_cells: Array = []
	for _lc in rest:
		if str(special.get(_lc, "")) == "lore":
			lore_cells.append(_lc)
	lore_cells.sort_custom(func(x, y): return int(dist.get(x, 0)) < int(dist.get(y, 0)))
	var term_of: Dictionary = {}
	var _ln: int = lore_cells.size()
	if _ln >= 1:
		term_of[lore_cells[_ln - 1]] = "gateway"
	if _ln >= 2:
		term_of[lore_cells[_ln - 2]] = "director"

	var mini_arch: String = String(arches[rng.randi() % arches.size()])

	var g0: Array = _blank()
	_put(g0, 3, 3, "T"); _put(g0, 2, 2, "*"); _put(g0, 19, 2, "*")
	_rect(g0, 9, 5, 12, 6, "=")
	r[SPAWN] = {"grid": g0, "zone": "reception", "style": "clean", "hub": true, "term": "reception"}

	var g1: Array = _blank()
	_put(g1, 3, 2, "*"); _put(g1, 18, 2, "*")
	_rect(g1, 8, 7, 13, 7, "=")
	_put(g1, 6, 5, "e"); _put(g1, 14, 5, "e"); _put(g1, 10, 4, "f"); _put(g1, 10, 8, "s")
	r[ENEMY] = {"grid": g1, "zone": "reception", "style": "clean", "combat_intro": true}

	var g2: Array = _blank()
	_put(g2, 5, 5, "="); _put(g2, 15, 6, "="); _put(g2, 3, 2, "*"); _put(g2, 18, 2, "*")
	r[NOVA] = {"grid": g2, "zone": "openspace", "style": "office", "meet_nova": true}

	for c in cells:
		if c == NOVA:
			continue
		var frac: float = float(dist.get(c, 0)) / float(maxd)
		var zi: int = clampi(int(frac * 3.999), 0, 3)
		var zn: String = str(zseq[zi])
		var meta: Dictionary = {}
		if c == boss_cell:
			var g: Array = _blank_sized(28, 18)
			_round_corners(g, 4)
			_put(g, 14, 6, "b")
			_put(g, 5, 12, "o"); _put(g, 22, 12, "o")
			_put(g, 14, 13, "V")
			_put(g, 3, 3, "*"); _put(g, 24, 3, "*")
			meta = {"grid": g, "zone": zn, "style": str(style_of.get(zn, "clean")), "zoom": 0.85, "boss": "admin", "descent": true}
		else:
			var kind: String = str(special.get(c, ""))
			if kind == "miniboss":
				var g: Array = _blank_sized(28, 18)
				_round_corners(g, 4)
				_put(g, 14, 6, "b")
				_put(g, 4, 4, "o"); _put(g, 23, 4, "o")
				_put(g, 3, 3, "*"); _put(g, 24, 3, "*")
				meta = {"grid": g, "zone": zn, "style": str(style_of.get(zn, "clean")), "zoom": 0.9, "boss": mini_arch}
			elif kind == "shop":
				var g: Array = _blank()
				_put(g, 6, 5, "$"); _put(g, 10, 5, "$"); _put(g, 14, 5, "$")
				_rect(g, 4, 7, 17, 7, "=")
				_put(g, 3, 2, "*"); _put(g, 10, 2, "*"); _put(g, 18, 2, "*")
				meta = {"grid": g, "zone": zn, "style": "shop", "shop": true}
			elif kind == "treasure":
				var g: Array = _blank()
				_put(g, 10, 5, "M")
				var lets: Array = ["J", "X", "H", "C"]
				_put(g, 13, 5, str(lets[rng.randi() % lets.size()]))
				_put(g, 7, 5, "z"); _put(g, 4, 8, "o")
				_put(g, 10, 2, "*")
				meta = {"grid": g, "zone": zn, "style": str(style_of.get(zn, "clean"))}
			elif kind == "secret":
				var g: Array = _blank()
				_put(g, 10, 5, "T"); _put(g, 6, 6, "+"); _put(g, 14, 6, "+"); _put(g, 10, 8, "M")
				_put(g, 4, 2, "*"); _put(g, 16, 2, "*")
				meta = {"grid": g, "zone": zn, "style": "clean", "easter": true}
			elif kind == "lore":
				var g: Array = _blank()
				_put(g, 10, 5, "T"); _put(g, 5, 7, "+"); _put(g, 15, 7, "+")
				_put(g, 10, 2, "*")
				meta = {"grid": g, "zone": zn, "style": str(style_of.get(zn, "clean"))}
				meta["term"] = str(term_of.get(c, "log"))
			else:
				var _opt = [[22,12,1.4],[28,14,1.2],[24,18,1.15],[26,16,1.2]][rng.randi() % 4]
				var g: Array = _blank_sized(_opt[0], _opt[1])
				if rng.randf() < 0.3:
					_round_corners(g, 4 + rng.randi() % 3)
				_gen_room(g, rng, zn, frac)
				meta = {"grid": g, "zone": zn, "style": str(style_of.get(zn, "clean")), "zoom": _opt[2]}
		r[c] = meta
	return r
