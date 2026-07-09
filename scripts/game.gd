extends Node2D

const RoomData = preload("res://scripts/rooms.gd")
const PlayerScript = preload("res://scripts/player.gd")
const NovaScript = preload("res://scripts/nova.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const MiniBossScript = preload("res://scripts/miniboss.gd")
const BulletScript = preload("res://scripts/bullet.gd")
const BossScript = preload("res://scripts/boss.gd")
const VirusScript = preload("res://scripts/virusboss.gd")
const AudioScript = preload("res://scripts/audio.gd")
const MobileScript = preload("res://scripts/mobile_controls.gd")

const TILE := 16
const COLS := 22
const ROWS := 12
const SAVE_PATH := "user://nova_save.cfg"
const META_PATH := "user://nova_meta.cfg"

enum St { BOOT_ENGINE, BOOT_LOGO, MENU, INTRO, PLAY, DIALOG, VIRUS, TRANSFORM, BOSS, WIN, CHOICE, BOSS_INTRO, NOVA_CUT, ENDING, DEATH }

var state: int = St.BOOT_LOGO
var paused := false
var map_open := false
var boot_t := 0.0
var menu_t := 0.0
var start_anim := 0.0
var cut_t := 0.0
var cut_phase := 0
var has_save := false
var ng_plus := 0

var rooms: Dictionary = {}
var room_pos: Vector2i = Vector2i(0, 0)
var grid: Array = []
var decor_grid: Array = []
var style: String = "clean"
var zone: String = "reception"
var doors: Dictionary = {}
var cleared: Dictionary = {}
var visited: Dictionary = {}
var gate_open: Dictionary = {}
var collected: Dictionary = {}
var hearts_taken: Dictionary = {}
var puzzle_solved: Dictionary = {}
var bought: Dictionary = {}
var lamps: Array = []
var has_key := false
var nova_found := false
var merciful := false
var room_had_enemies := false
var wave_queue: Array = []
var wave_cd := 0.0
var rooms_cleared := 0
var currency := 0
var kill_combo := 0
var combo_t := 0.0
var combo_best := 0

var player = null
var nova = null
var boss = null
var virus = null
var audio = null
var mobile = null
var enemies: Array = []
var bullets: Array = []
var shake := 0.0
var bg_scroll := 0.0
var glitch_level := 0.0
var laser_on := false
var laser_t := 0.0

var abilities: Dictionary = {"spread": false, "dash": false, "nova_hack": false, "blast": false}

var entry_point: Vector2 = Vector2.ZERO
var dialog_lines: Array = []
var dialog_idx := 0
var dialog_after := ""

var chat_queue: Array = []
var chat_full := ""
var chat_shown := ""
var chat_char := 0.0
var chat_hold := 0.0
var idle_cd := 6.0
var lucid_flash := 0.0

var tf_hold := 0.0

var ui: CanvasLayer
var lbl_top: Label
var lbl_boss: Label
var font: Font
var _banner_text := ""
var _banner_a := 0.0

var pal: Dictionary = {
	"clean":    {"f0": Color(0.14,0.18,0.24), "f1": Color(0.12,0.16,0.21), "wall": Color(0.24,0.30,0.40), "ac": Color(0.35,0.75,0.9)},
	"office":   {"f0": Color(0.17,0.16,0.14), "f1": Color(0.15,0.14,0.12), "wall": Color(0.30,0.28,0.24), "ac": Color(0.9,0.7,0.35)},
	"glass":    {"f0": Color(0.11,0.16,0.20), "f1": Color(0.10,0.14,0.18), "wall": Color(0.20,0.30,0.40), "ac": Color(0.5,0.85,1.0)},
	"archive":  {"f0": Color(0.16,0.12,0.09), "f1": Color(0.13,0.10,0.07), "wall": Color(0.34,0.24,0.15), "ac": Color(0.85,0.6,0.3)},
	"shop":     {"f0": Color(0.10,0.16,0.13), "f1": Color(0.09,0.14,0.11), "wall": Color(0.18,0.30,0.22), "ac": Color(0.4,0.95,0.6)},
	"server":   {"f0": Color(0.10,0.10,0.16), "f1": Color(0.08,0.08,0.14), "wall": Color(0.20,0.20,0.34), "ac": Color(0.5,0.5,1.0)},
	"pipes":    {"f0": Color(0.10,0.16,0.18), "f1": Color(0.08,0.13,0.15), "wall": Color(0.16,0.28,0.32), "ac": Color(0.3,0.85,0.85)},
	"approach": {"f0": Color(0.15,0.08,0.09), "f1": Color(0.12,0.06,0.07), "wall": Color(0.30,0.14,0.16), "ac": Color(1.0,0.4,0.35)},
	"core":     {"f0": Color(0.14,0.06,0.12), "f1": Color(0.11,0.05,0.10), "wall": Color(0.28,0.10,0.22), "ac": Color(1.0,0.3,0.4)},
}
var zone_name: Dictionary = {"reception":"РЕСЕПШН","openspace":"ОПЕНСПЕЙС","meeting":"ПЕРЕГОВОРНЫЕ","archive":"РђР РҐРИВ","server":"СЕРВЕРНАЯ","tech":"ТЕХЭТАЖ","approach":"ПОДСТУП К ЯДРУ","core":"ЯДРО"}
var zone_music: Dictionary = {"reception":"maint","openspace":"assembly","meeting":"assembly","archive":"maint","server":"server","tech":"tech","approach":"approach","core":"core"}
var zone_glitch: Dictionary = {"reception":0.0,"openspace":0.12,"meeting":0.28,"archive":0.4,"server":0.55,"tech":0.7,"approach":0.85,"core":0.9}
var zone_dark: Dictionary = {"reception":0.0,"openspace":0.0,"meeting":0.0,"archive":0.15,"server":0.55,"tech":0.68,"approach":0.8,"core":0.82}
var zone_tint: Dictionary = {"reception": Color(0.6,0.75,1.0), "openspace": Color(0.9,0.8,0.6), "meeting": Color(0.6,0.85,1.0), "archive": Color(0.9,0.7,0.4), "server": Color(0.4,0.5,1.0), "tech": Color(0.4,0.9,0.9), "approach": Color(1.0,0.4,0.35), "core": Color(1.0,0.3,0.4)}

var dlg_t0 := 0.0
var event_seen: Dictionary = {}
var lore_idx := 0
var choice_a: Dictionary = {}
var choice_b: Dictionary = {}
var choice_c: Dictionary = {}
var choice_tile := ""
var choice_t := 0.0
var dmg_bonus := 0.0
var dmg_nums: Array = []
var reduce_shake := false
var difficulty := 1
var game_time := 0.0
var save_flash := 0.0
var chapter := 1
var chapter_seed := 0
var chapter_banner := ""
var chapter_banner_sub := ""
var chapter_banner_t := 0.0
var pending_boss = null
var boss_intro_ref = null
var boss_intro_t := 0.0
var boss_intro_name := ""
var boss_intro_line := ""
var parts: Array = []
var room_fade := 0.0
var scars: Array = []
var meta_cores := 0
var ending := ""
var hitstop := 0.0
var item_cd := 0.0
var item_max := 9.0
var dmg_dir := Vector2.ZERO
var dmg_flash := 0.0
var seed_entry := false
var seed_input := ""
var has_custom_seed := false
var descent_ready := false
var ability_lvl: Dictionary = {"spread":0,"dash":0,"nova_hack":0,"blast":0}
var pclass := 0
var lang := 0  # 0 = RU, 1 = EN
var key_interact := KEY_E
var key_weapon := KEY_Q
var key_pulse := KEY_F
var key_item := KEY_R
var key_shield := KEY_G
var rebind_idx := -1
var nova_cut_t := 0.0
var end_t := 0.0
var end_phase := 0
var core_glitch_t := 0.0
var core_glitch_kind := 0
var core_glitch_cd := 8.0
var nova_saved := false
var secret_boss := false
var deaths := 0
var death_flash := 0.0
var death_line := ""
var win_t := 0.0
var item2_cd := 0.0
var item2_max := 12.0
var shield_t := 0.0
var broke_walls: Dictionary = {}
var death_t := 0.0
var death_pos := Vector2.ZERO
var world_root: Node2D = null
var cam := Vector2.ZERO
var zoom := 1.4
var shake_px := Vector2.ZERO
var RW := 22
var RH := 12
var room_zoom := 1.4
var dark_room := false
var weapon_mods: Dictionary = {"burn": false, "freeze": false}

func _ready() -> void:
	randomize()
	font = ThemeDB.fallback_font
	var _ff := FontFile.new()
	if _ff.load_dynamic_font("res://font.ttf") == OK:
		font = _ff
	chapter = 1
	chapter_seed = randi()
	rooms = RoomData.chapter_map(1, chapter_seed)
	audio = AudioScript.new()
	add_child(audio)
	world_root = Node2D.new()
	add_child(world_root)
	has_save = FileAccess.file_exists(SAVE_PATH)
	if has_save:
		var cf := ConfigFile.new()
		if cf.load(SAVE_PATH) == OK:
			ng_plus = cf.get_value("s", "ng_plus", 0)
	var mf := ConfigFile.new()
	if mf.load(META_PATH) == OK:
		meta_cores = mf.get_value("m", "cores", 0)
		lang = mf.get_value("m", "lang", 0)
		key_interact = mf.get_value("m", "k_interact", KEY_E)
		key_weapon = mf.get_value("m", "k_weapon", KEY_Q)
		key_pulse = mf.get_value("m", "k_pulse", KEY_F)
		key_item = mf.get_value("m", "k_item", KEY_R)
		key_shield = mf.get_value("m", "k_shield", KEY_G)
	_build_ui()
	mobile = MobileScript.new()
	mobile.game = self
	add_child(mobile)
	player = PlayerScript.new()
	player.game = self
	player.visible = false
	world_root.add_child(player)
	nova = NovaScript.new()
	nova.game = self
	nova.player = player
	nova.menu_mode = true
	nova.visible = false
	nova.position = Vector2(COLS * TILE * 0.5, ROWS * TILE * 0.5)
	world_root.add_child(nova)
	state = St.BOOT_LOGO

func tile_at(tx: int, ty: int) -> String:
	if ty < 0 or ty >= grid.size() or tx < 0 or tx >= RW:
		return "."
	var row: String = grid[ty]
	if tx >= row.length():
		return "."
	return row[tx]

func decor_tile_at(tx: int, ty: int) -> String:
	if ty < 0 or ty >= decor_grid.size() or tx < 0:
		return "#"
	var row: String = str(decor_grid[ty])
	return row[tx] if tx < row.length() else "#"

func set_tile(tx: int, ty: int, ch: String) -> void:
	if ty < 0 or ty >= grid.size() or tx < 0 or tx >= RW:
		return
	var row: String = grid[ty]
	if tx >= row.length():
		return
	grid[ty] = row.substr(0, tx) + ch + row.substr(tx + 1)

func is_solid(tx: int, ty: int) -> bool:
	var c: String = tile_at(tx, ty)
	if c == "#" or c == "o" or c == "=" or c == "y" or c == "w":
		return true  # w = breakable barrier, solid until blown
	if c == "g":
		return not puzzle_solved.get(room_pos, false)
	if c == "k":
		return not has_key
	if c == "D":
		return _door_locked(doors.get(Vector2i(tx, ty), ""))
	return false

func hit_tile(tx: int, ty: int) -> bool:
	var c: String = tile_at(tx, ty)
	if c == "#" or c == "=":
		return true
	if c == "w":
		return true  # solid to bullets; only the EMI grenade cracks it open
	if c == "*":
		set_tile(tx, ty, ".")
		var _lp := Vector2(tx * TILE + TILE * 0.5, ty * TILE + TILE * 0.5)
		for _li in range(lamps.size() - 1, -1, -1):
			if lamps[_li].distance_to(_lp) < 2.0: lamps.remove_at(_li)
		_spawn_death_burst(_lp, Color(1.0, 0.95, 0.7))
		if audio: audio.sfx("ehit")
		return true
	if c == "y":
		_hit_target(tx, ty)
		return true
	if c == "o":
		_explode_barrel(tx, ty)
		return true
	if c == "g":
		return not puzzle_solved.get(room_pos, false)
	if c == "k":
		return not has_key
	if c == "D":
		return _door_locked(doors.get(Vector2i(tx, ty), ""))
	return false

func _hit_target(tx: int, ty: int) -> void:
	set_tile(tx, ty, "Y")
	if audio: audio.sfx("ehit")
	shake = max(shake, 0.15)
	var remaining := 0
	for y in range(RH):
		for x in range(RW):
			if tile_at(x, y) == "y": remaining += 1
	if remaining == 0 and not puzzle_solved.get(room_pos, false):
		puzzle_solved[room_pos] = true
		set_tile_all("g", ".")
		if audio: audio.sfx("gate")
		shake = 0.4
		say("Все цели поражены. Барьер снят!")

func _explode_barrel(tx: int, ty: int) -> void:
	set_tile(tx, ty, ".")
	scars.append({"x": tx * TILE + TILE * 0.5, "y": ty * TILE + TILE * 0.5, "kind": 0})
	if audio: audio.sfx("explode")
	shake = max(shake, 0.4)
	var c := Vector2(tx * TILE + TILE * 0.5, ty * TILE + TILE * 0.5)
	for e in enemies.duplicate():
		if e != null and is_instance_valid(e) and e.position.distance_to(c) < 30.0:
			e.hurt(32.0)
	if boss != null and is_instance_valid(boss) and boss.position.distance_to(c) < 30.0:
		boss.hurt(20.0)
	if virus != null and is_instance_valid(virus) and virus.position.distance_to(c) < 34.0:
		virus.hurt(20.0)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if (dx != 0 or dy != 0) and tile_at(tx + dx, ty + dy) == "o":
				set_tile(tx + dx, ty + dy, ".")
				var cc := Vector2((tx + dx) * TILE + TILE * 0.5, (ty + dy) * TILE + TILE * 0.5)
				for e2 in enemies.duplicate():
					if is_instance_valid(e2) and e2.position.distance_to(cc) < 30.0:
						e2.hurt(32.0)
	if is_instance_valid(player) and player.position.distance_to(c) < 22.0:
		player.hit(1.0)

func _door_locked(side: String) -> bool:
	if side == "":
		return true
	if state == St.VIRUS or state == St.BOSS or state == St.TRANSFORM:
		return true
	if not _is_cleared(room_pos):
		return true
	return false

func _is_cleared(pos: Vector2i) -> bool:
	return cleared.get(pos, false)

func is_active() -> bool:
	return (state == St.PLAY or state == St.VIRUS or state == St.BOSS) and not paused and not map_open and hitstop <= 0.0

func _load_room(pos: Vector2i, side: String) -> void:
	room_pos = pos
	pending_boss = null
	room_fade = 1.0
	scars.clear()
	var info: Dictionary = rooms[pos]
	style = info["style"]
	zone = info.get("zone", RoomData.zone_of(pos))
	descent_ready = bool(info.get("descent", false))
	visited[pos] = true
	grid = (info["grid"] as Array).duplicate(true)
	RH = grid.size()
	RW = 0
	for _rr in grid:
		RW = max(RW, str(_rr).length())
	if RW < 4: RW = 22
	if RH < 4: RH = 12
	room_zoom = float(info.get("zoom", 1.4))
	_normalize_grid()
	doors = {}
	_carve_doors()
	# Immutable room snapshot used only by procedural decor. Gameplay may mutate grid,
	# but furniture must never jump when a pickup disappears.
	decor_grid = grid.duplicate(true)
	lamps.clear()
	for y in range(RH):
		for x in range(RW):
			var cc: String = tile_at(x, y)
			if cc == "M" and hearts_taken.get(_hid(x, y), false):
				set_tile(x, y, ".")
			elif cc == "$" and bought.get(_hid(x, y), false):
				set_tile(x, y, ".")
			elif cc == "w" and broke_walls.get(_hid(x, y), false):
				set_tile(x, y, ".")
			elif cc == "*":
				lamps.append(Vector2(x * TILE + TILE*0.5, y * TILE + TILE*0.5))
	if puzzle_solved.get(pos, false):
		set_tile_all("g", ".")
		set_tile_all("y", "Y")
	for e in enemies:
		if is_instance_valid(e): e.queue_free()
	enemies.clear()
	for b in bullets:
		if is_instance_valid(b): b.queue_free()
	bullets.clear()
	if boss != null and is_instance_valid(boss): boss.queue_free()
	boss = null
	if virus != null and is_instance_valid(virus): virus.queue_free()
	virus = null

	var has_core := false
	room_had_enemies = false
	wave_queue.clear()
	wave_cd = 0.0
	var kind_of: Dictionary = {"e":"ground","f":"fly","s":"turret","u":"hunter","z":"elite","p":"bomber","q":"shielder","r":"healer"}
	var spawn_spots: Array = []
	for y in range(RH):
		for x in range(RW):
			var c: String = tile_at(x, y)
			var px := Vector2(x * TILE + TILE * 0.5, y * TILE + TILE * 0.5)
			if kind_of.has(c):
				spawn_spots.append({"px": px, "kind": kind_of[c]})
				room_had_enemies = true
			elif c == "b":
				_spawn_miniboss(px, pos); set_tile(x, y, "."); room_had_enemies = true
			elif c == "B":
				has_core = true; set_tile(x, y, ".")
	if spawn_spots.size() >= 5:
		var first: int = 3
		for i in range(spawn_spots.size()):
			var sp: Dictionary = spawn_spots[i]
			if i < first:
				_spawn_enemy(sp["px"], sp["kind"])
			else:
				wave_queue.append(sp)
		wave_cd = 2.4
	else:
		for sp in spawn_spots:
			_spawn_enemy(sp["px"], sp["kind"])

	_place_player(side)
	entry_point = player.position
	_snap_camera()
	glitch_level = zone_glitch.get(zone, 0.0)
	dark_room = bool(info.get("dark", false))
	if audio: audio.play_music(zone_music.get(zone, "maint"))
	if audio: audio.set_intensity(room_had_enemies)

	if not room_had_enemies:
		cleared[pos] = true

	if has_core:
		_start_virus()
		return
	if info.get("meet_nova", chapter == 1 and RoomData.meet_nova(pos)) and not nova_found:
		_reveal_nova()
	else:
		_show_zone_banner()
		_room_enter_chatter()
		if dark_room:
			_flash("СВЕТ ВЫРУБЛЕН")
			say("Темнота... держись в моём свете. они рядом.")
		Extras.random_event(self)
	_save_checkpoint()
	if pending_boss != null and is_instance_valid(pending_boss):
		_start_boss_intro(pending_boss)

func _normalize_grid() -> void:
	while grid.size() < RH:
		grid.append("#".repeat(RW))
	if grid.size() > RH:
		grid.resize(RH)
	for i in range(RH):
		var row: String = str(grid[i])
		if row.length() < RW:
			row += "#".repeat(RW - row.length())
		elif row.length() > RW:
			row = row.substr(0, RW)
		grid[i] = row

func _reveal_nova() -> void:
	nova_found = true
	nova.visible = false
	nova.menu_mode = false
	nova.position = player.position + Vector2(20, -8)
	nova_cut_t = 0.0
	state = St.NOVA_CUT
	dialog_idx = 0
	dialog_after = ""
	if audio: audio.sfx("select")
	dialog_lines = [
		"РИз-под мёртвого стола мигает синий огонёк. Маленький дрон.",
		"Он не заражён. Он... прятался. Ждал.",
		"NOVA: ты живой? настоящий человек? я думала, я осталась одна.",
		"NOVA: я Nova, ремонтный юнит. я не дам им тебя тронуть.",
		"NOVA: держись рядом. коснись кнопки NOVA, и я ударю врагов током. вместе дойдём до ядра.",
	]
	_render_dialog()

func _nova_dialog() -> void:
	nova.visible = true
	state = St.DIALOG
	dialog_idx = 0
	if audio: audio.sfx("blip")
	_render_dialog()

func _carve_doors() -> void:
	var dirs := {"U": Vector2i(0,-1), "D": Vector2i(0,1), "L": Vector2i(-1,0), "R": Vector2i(1,0)}
	for sidek in dirs.keys():
		var np: Vector2i = room_pos + dirs[sidek]
		if not rooms.has(np):
			continue
		var mcx: int = int(RW / 2)
		var mcy: int = int(RH / 2)
		match sidek:
			"U": set_tile(mcx-1,0,"D"); set_tile(mcx,0,"D"); doors[Vector2i(mcx-1,0)]="U"; doors[Vector2i(mcx,0)]="U"
			"D": set_tile(mcx-1,RH-1,"D"); set_tile(mcx,RH-1,"D"); doors[Vector2i(mcx-1,RH-1)]="D"; doors[Vector2i(mcx,RH-1)]="D"
			"L": set_tile(0,mcy-1,"D"); set_tile(0,mcy,"D"); doors[Vector2i(0,mcy-1)]="L"; doors[Vector2i(0,mcy)]="L"
			"R": set_tile(RW-1,mcy-1,"D"); set_tile(RW-1,mcy,"D"); doors[Vector2i(RW-1,mcy-1)]="R"; doors[Vector2i(RW-1,mcy)]="R"

func _hid(x: int, y: int) -> String:
	return str(chapter) + ":" + str(room_pos.x) + "," + str(room_pos.y) + "," + str(x) + "," + str(y)

func _place_player(side: String) -> void:
	var mcx: float = RW * 0.5 * TILE
	var mcy: float = RH * 0.5 * TILE
	match side:
		"start": player.position = Vector2(4 * TILE, mcy)
		"R": player.position = Vector2(TILE + player.hx, mcy)
		"L": player.position = Vector2((RW - 1) * TILE - player.hx, mcy)
		"D": player.position = Vector2(mcx, TILE + player.hy)
		"U": player.position = Vector2(mcx, (RH - 1) * TILE - player.hy)
	player.vx = 0.0; player.vy = 0.0

func _spawn_enemy(px: Vector2, kind: String) -> void:
	var e = EnemyScript.new()
	e.game = self
	e.player = player
	e.kind = kind
	e.position = px
	var base := 22.0
	match kind:
		"fly": base = 15.0
		"turret": base = 28.0
		"hunter": base = 20.0
		"elite": base = 130.0
		"bomber": base = 24.0
		"shielder": base = 42.0
		"healer": base = 30.0
	e.hp = base * _zone_mult()
	e.max_hp = e.hp
	enemies.append(e)
	world_root.add_child(e)

func _spawn_miniboss(px: Vector2, pos: Vector2i) -> void:
	var m = MiniBossScript.new()
	m.game = self
	m.player = player
	m.arch = String((rooms.get(pos, {}) as Dictionary).get("boss", RoomData.boss_arch(pos)))
	m.position = px
	var base := 300.0
	if m.arch == "hive": base = 260.0
	m.max_hp = base * _zone_mult() * 1.6
	m.hp = m.max_hp
	enemies.append(m)
	world_root.add_child(m)
	pending_boss = m

func summon_add(px: Vector2, kind: String) -> void:
	_spawn_enemy(px, kind)

func T(ru: String, en: String) -> String:
	return en if lang == 1 else ru

func _save_lang() -> void:
	var mf := ConfigFile.new()
	mf.load(META_PATH)
	mf.set_value("m", "cores", meta_cores)
	mf.set_value("m", "lang", lang)
	mf.set_value("m", "k_interact", key_interact)
	mf.set_value("m", "k_weapon", key_weapon)
	mf.set_value("m", "k_pulse", key_pulse)
	mf.set_value("m", "k_item", key_item)
	mf.set_value("m", "k_shield", key_shield)
	mf.save(META_PATH)

func dmg_mult() -> float:
	return 1.0 + dmg_bonus

func core_invert() -> bool:
	return core_glitch_t > 0.0 and core_glitch_kind == 0

func core_gravity() -> float:
	return 120.0 if (core_glitch_t > 0.0 and core_glitch_kind == 1) else 0.0

func _zone_mult() -> float:
	var z := 1.0
	match zone:
		"meeting": z = 1.15
		"archive": z = 1.25
		"server": z = 1.4
		"tech": z = 1.55
		"approach": z = 1.7
		"core": z = 1.8
	var dm: float = [0.72, 1.0, 1.4][difficulty]
	return z * dm * (1.0 + rooms_cleared * 0.02) * (1.0 + ng_plus * 0.4) * (1.0 + float(chapter - 1) * 0.22)

func enemy_speed_mult() -> float:
	var z := 1.0
	match zone:
		"server", "tech": z = 1.15
		"approach", "core": z = 1.25
	return z * (1.0 + ng_plus * 0.1)

func _try_transition() -> void:
	if state != St.PLAY:
		return
	var p: Vector2 = player.position
	var w: float = RW * TILE
	var h: float = RH * TILE
	var dc := Vector2i.ZERO
	var side := ""
	if p.x < 0.0: dc = Vector2i(-1,0); side = "L"
	elif p.x > w: dc = Vector2i(1,0); side = "R"
	elif p.y < 0.0: dc = Vector2i(0,-1); side = "U"
	elif p.y > h: dc = Vector2i(0,1); side = "D"
	else: return
	var np: Vector2i = room_pos + dc
	if rooms.has(np):
		if audio: audio.sfx("door")
		_load_room(np, side)
	else:
		player.position.x = clamp(p.x, player.hx, w - player.hx)
		player.position.y = clamp(p.y, player.hy, h - player.hy)

func try_collect() -> void:
	var tx := int(floor(player.position.x / TILE))
	var ty := int(floor(player.position.y / TILE))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var c: String = tile_at(tx + dx, ty + dy)
			if "JXHC".find(c) >= 0 and not collected.get(c, false):
				_offer_choice(c)
			elif c == "1" and not collected.get("1", false):
				collected["1"] = true; set_tile(tx+dx, ty+dy, ".")
				player.owned[1] = true; player.weapon = 1
				if audio: audio.sfx("pickup")
				_flash("РћР РЈР–РИЕ: ВЕЕРНЫЙ Р”Р РћР‘РћР’РИК (Q)")
				say("Дробовик! кнопка ОРУЖ переключает ствол. Он страшен только вблизи.")
			elif c == "2" and not collected.get("2", false):
				collected["2"] = true; set_tile(tx+dx, ty+dy, ".")
				player.owned[2] = true; player.weapon = 2
				if audio: audio.sfx("pickup")
				_flash("РћР РЈР–РИЕ: РџР РћР‘РИВНОЙ РЕЛЬСОТРОН (Q)")
				say("Рельсотрон! Пробивает толпу в линию.")
			elif c == "K" and not has_key:
				has_key = true; set_tile(tx+dx, ty+dy, ".")
				if audio: audio.sfx("pickup")
				_flash("КЛЮЧ-КАРТА ПОЛУЧЕНА")
				say("Ключ-карта! Теперь пройдём запертые двери.")
			elif c == "!":
				set_tile(tx+dx, ty+dy, ".")
				var mp := Vector2((tx+dx) * TILE + TILE*0.5, (ty+dy) * TILE + TILE*0.5)
				_spawn_enemy(mp, "hunter")
				room_had_enemies = true
				cleared[room_pos] = false
				shake = 0.4
				if audio: audio.sfx("glitch")
				_flash("ЭТО ЛОВУШКА!")
				say("Мимик! Аптечки тут врут. Осторожней.")
			elif c == "+":
				set_tile(tx+dx, ty+dy, "."); player.heal(2.0)
				if audio: audio.sfx("pickup")
				_flash("АПТЕЧКА +2")
			elif c == "M":
				hearts_taken[_hid(tx+dx, ty+dy)] = true; set_tile(tx+dx, ty+dy, ".")
				player.max_hp += 2.0; player.hp = player.max_hp; shake = 0.3
				if audio: audio.sfx("heart")
				_flash("КОНТЕЙНЕР ЗДОРОВЬЯ +2 МАКС HP")
				say("Больше брони. Мне спокойнее, когда ты живой.")

func _grant(c: String) -> void:
	collected[c] = true
	set_tile_all(c, ".")
	if audio: audio.sfx("pickup")
	match c:
		"J":
			abilities["spread"] = true
			_flash("РЈР›РЈР§РЁР•РќРИЕ: ТРОЙНОЙ ЗАЛП")
			say("Модуль рассеивания. Бластер бьёт веером.")
		"X":
			abilities["dash"] = true
			_flash("РЈР›РЈР§РЁР•РќРИЕ: РЫВОК")
			say("Ускоритель! кнопка РЫВ. Рывок бьёт всех на пути и даёт неуязвимость.")
		"H":
			abilities["nova_hack"] = true
			_flash("РЈР›РЈР§РЁР•РќРИЕ: ВЗЛОМ NOVA")
			say("Модуль взлома! Теперь мой импульс (кнопка NOVA) вербует слабых врагов на твою сторону.")
		"C":
			abilities["blast"] = true
			_flash("РЈР›РЈР§РЁР•РќРИЕ: РЈРЎРИЛЕННЫЙ ЗАЛП")
			say("Перегружаю твою пушку. Больно им будет.")
	nova.ping(); shake = 0.25

func _offer_choice(c: String) -> void:
	choice_tile = c
	choice_t = 0.0
	choice_a = _ability_card(c)
	choice_b = _perk_card(c)
	choice_c = _greed_card()
	if audio: audio.sfx("select")
	state = St.CHOICE

func _ability_card(c: String) -> Dictionary:
	match c:
		"J": return {"kind":"ability","key":"spread","name":"ТРОЙНОЙ ЗАЛП","desc":"Бластер бьёт веером из трёх пуль сразу"}
		"X": return {"kind":"ability","key":"dash","name":"РЫВОК","desc":"Рывок сквозь врагов, даёт неуязвимость"}
		"H": return {"kind":"ability","key":"nova_hack","name":"ВЗЛОМ NOVA","desc":"РИмпульс Nova вербует слабых врагов на твою сторону"}
		"C": return {"kind":"ability","key":"blast","name":"РЈРЎРИЛЕННЫЙ ЗАЛП","desc":"Пушка перегружена, урон заметно выше"}
	return {"kind":"ability","key":"spread","name":"МОДУЛЬ","desc":""}

func _perk_card(c: String) -> Dictionary:
	match c:
		"J": return {"kind":"maxhp","name":"Р‘Р РћРќР•РџР›РђРЎРўРИНА","desc":"+4 к максимуму HP навсегда","amt":4.0}
		"X": return {"kind":"dmg","name":"ПЕРЕГРУЗКА СТВОЛА","desc":"+30% урона навсегда","amt":0.30}
		"H": return {"kind":"heal","name":"РЕМБОТ","desc":"+3 макс HP и полное лечение","amt":3.0}
		"C": return {"kind":"dmg","name":"РАЗРЫВНЫЕ РџРЈР›РИ","desc":"+35% урона навсегда","amt":0.35}
	return {"kind":"maxhp","name":"БРОНЯ","desc":"+2 макс HP","amt":2.0}

func _greed_card() -> Dictionary:
	var roll: int = randi() % 3
	if roll == 0:
		return {"kind":"cash","name":"ТРОФЕЙ","desc":"+10 валюты сразу","amt":10.0}
	elif roll == 1:
		return {"kind":"heal","name":"АПТЕЧКА","desc":"+2 макс HP и полное лечение","amt":2.0}
	return {"kind":"dmg","name":"КАЛИБРОВКА","desc":"+20% урона навсегда","amt":0.20}

func _reroll_choice() -> void:
	if currency < 3:
		if audio: audio.sfx("deny")
		return
	currency -= 3
	var letters := ["J", "X", "H", "C"]
	choice_a = _ability_card(letters[randi() % 4])
	choice_b = _perk_card(letters[randi() % 4])
	choice_c = _greed_card()
	choice_t = 0.0
	if audio: audio.sfx("select")

func _pick_choice(which: int) -> void:
	var card: Dictionary = choice_a
	if which == 1: card = choice_b
	elif which == 2: card = choice_c
	collected[choice_tile] = true
	set_tile_all(choice_tile, ".")
	match String(card.get("kind", "")):
		"ability":
			if abilities.get(card["key"], false):
				ability_lvl[card["key"]] = int(ability_lvl.get(card["key"], 0)) + 1
				if card["key"] == "nova_hack" and nova != null: nova.pulse_bonus += 0.5
			else:
				abilities[card["key"]] = true
			_flash("РЈР›РЈР§РЁР•РќРИЕ: " + String(card["name"]))
			say(String(card["desc"]))
		"maxhp":
			player.max_hp += float(card["amt"]); player.hp = player.max_hp
			_flash("ВЫБРАНО: " + String(card["name"]))
			say("Больше брони. Мне спокойнее, когда ты живой.")
		"heal":
			player.max_hp += float(card["amt"]); player.hp = player.max_hp
			_flash("ВЫБРАНО: " + String(card["name"]))
			say("Починила тебя. Как новенький.")
		"cash":
			currency += int(card["amt"])
			_flash("+" + str(int(card["amt"])) + "$")
		"dmg":
			dmg_bonus += float(card["amt"])
			_flash("ВЫБРАНО: " + String(card["name"]))
			say("Твоя пушка теперь злее. Мне это даже нравится.")
	if audio: audio.sfx("pickup")
	if nova_found and nova != null and not nova.infected and audio: audio.sfx("nova_ok")
	nova.ping(); shake = 0.25
	state = St.PLAY
	_save_checkpoint()

func set_tile_all(ch: String, to: String) -> void:
	for y in range(RH):
		for x in range(RW):
			if tile_at(x, y) == ch:
				set_tile(x, y, to)

func _offer_desc(off: Dictionary) -> String:
	match String(off.get("id", "")):
		"maxhp": return T("+2 к макс. здоровью навсегда", "+2 max HP, permanent")
		"heal": return T("полное восстановление HP", "restore all HP")
		"pulse": return T("импульс Nova перезаряжается быстрее", "Nova pulse recharges faster")
		"ability": return T("новая способность или аптечка", "a new ability or medkit")
	return ""

func _shop_offer(x: int, y: int) -> Dictionary:
	var idx: int = (x + y) % 4
	if idx == 3 and not (nova_found and nova != null and not nova.infected):
		idx = 1
	match idx:
		3: return {"id":"pulse", "name":"ИМПУЛЬС NOVA+", "cost": 6 + ng_plus}
		0: return {"id":"maxhp", "name":"+2 МАКС HP", "cost": 4 + ng_plus}
		1: return {"id":"heal", "name":"ПОЛНОЕ Р›Р•Р§Р•РќРИЕ", "cost": 3 + ng_plus}
		_: return {"id":"ability", "name":_next_ability_name(), "cost": 7 + ng_plus}

func _next_ability_name() -> String:
	if not abilities["blast"]: return "РЈРЎРИР›Р•РќРИЕ УРОНА"
	if not abilities["spread"]: return "ТРОЙНОЙ ЗАЛП"
	if not abilities["dash"]: return "РЫВОК"
	return "АПТЕЧКА +4"

func _buy(tx: int, ty: int) -> void:
	var off := _shop_offer(tx, ty)
	if currency < off["cost"]:
		if audio: audio.sfx("deny")
		_flash("НЕ ХВАТАЕТ ВАЛЮТЫ (" + str(off["cost"]) + ")")
		return
	currency -= off["cost"]
	bought[_hid(tx, ty)] = true
	set_tile(tx, ty, ".")
	if audio: audio.sfx("pickup")
	match off["id"]:
		"maxhp": player.max_hp += 2.0; player.hp = player.max_hp; _flash("КУПЛЕНО: +2 МАКС HP")
		"heal": player.hp = player.max_hp; _flash("КУПЛЕНО: ПОЛНОЕ Р›Р•Р§Р•РќРИЕ")
		"pulse":
			if nova != null: nova.pulse_bonus += 1.0
			_flash("ИМПУЛЬС NOVA БЫСТРЕЕ")
		"ability":
			if not abilities["blast"]: abilities["blast"] = true
			elif not abilities["spread"]: abilities["spread"] = true
			elif not abilities["dash"]: abilities["dash"] = true
			else: player.heal(4.0)
			_flash("КУПЛЕНО: " + off["name"])
	say("Разумная трата.")

func _buy_merchant(tx: int, ty: int) -> void:
	var cost := 9 + ng_plus
	if currency < cost:
		if audio: audio.sfx("deny")
		_flash("НЕ ХВАТАЕТ ВАЛЮТЫ (" + str(cost) + ")")
		return
	var avail: Array = []
	for kmod in ["burn", "freeze"]:
		if not weapon_mods.get(kmod, false): avail.append(kmod)
	if avail.is_empty():
		if audio: audio.sfx("deny")
		_flash("ВСЁ УЖЕ КУПЛЕНО")
		return
	currency -= cost
	var pick: String = avail[randi() % avail.size()]
	weapon_mods[pick] = true
	set_tile(tx, ty, ".")
	if audio: audio.sfx("pickup")
	var nm := {"burn": "ЗАЖИГАТЕЛЬНЫЕ ПУЛИ", "freeze": "ЗАМОРОЗКА"}
	_flash("НАСАДКА: " + String(nm[pick]))
	say("Модуль на ствол. Работает на любом оружии.")

func interact() -> void:
	if state == St.DIALOG:
		_advance_dialog()
		return
	if state != St.PLAY:
		return
	var tx := int(floor(player.position.x / TILE))
	var ty := int(floor(player.position.y / TILE))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var c: String = tile_at(tx + dx, ty + dy)
			if c == "T":
				_open_terminal()
				return
			elif c == "$":
				_buy(tx + dx, ty + dy)
				return
			elif c == "V":
				_try_descend()
				return
			elif c == "W":
				_buy_merchant(tx + dx, ty + dy)
				return

func nova_pulse() -> void:
	if nova == null or not nova.can_pulse():
		if nova != null and nova.infected:
			_flash("NOVA потеряна. РИмпульса больше нет.")
		return
	nova.do_pulse()
	if audio: audio.sfx("gate")
	shake = max(shake, 0.28)
	var _deflected := 0
	for b in bullets.duplicate():
		if is_instance_valid(b) and b.team == "enemy" and b.position.distance_to(nova.position) < 54.0:
			b.team = "player"
			b.vel = -b.vel * 1.25
			b.col = Color(0.5, 1.0, 0.95)
			b.dmg = max(b.dmg, 7.0)
			b.pierce = max(b.pierce, 1)
			_deflected += 1
	if _deflected > 0:
		shake = max(shake, 0.32)
		lucid_flash = max(lucid_flash, 0.5)
		if audio: audio.sfx("deflect")
	for e in enemies.duplicate():
		if e != null and is_instance_valid(e) and e.position.distance_to(nova.position) < 48.0:
			if abilities["nova_hack"] and (e.kind == "ground" or e.kind == "fly") and e.hp > 6.0:
				e.hack()
			else:
				e.hurt(14.0)
				e.tele = 0.0
				e.fire_cd = max(e.fire_cd, 0.6)
	if virus != null and is_instance_valid(virus) and virus.position.distance_to(nova.position) < 52.0:
		virus.hurt(10.0)

func _open_terminal() -> void:
	state = St.DIALOG
	dialog_idx = 0
	dialog_after = ""
	if audio: audio.sfx("select")
	var _meta: Dictionary = rooms.get(room_pos, {}) as Dictionary
	var _tm: String = String(_meta.get("term", ""))
	if _tm == "reception":
		dialog_lines = ["РўР•Р РњРИНАЛ // ресепшн", "Этаж вырубился час назад. Потом роботы очнулись... не такими.", "Вирус в главном компьютере, к востоку. Ты пока один. РИщи уцелевших."]
	elif _tm == "director":
		dialog_lines = ["РўР•Р РњРИНАЛ // кабинет директора", "'Мы дали ядру самообучение. Оно училось. А потом... перестало нас слушать.'", "NOVA: ...значит, оно живое. как и я. мне от этого не легче."]
	elif _tm == "gateway":
		dialog_lines = ["РўР•Р РњРИНАЛ // шлюз к ядру", "За этой дверью - ядро. Назад дороги нет.", "NOVA: Что бы ни случилось там... спасибо, что дошёл со мной."]
	elif bool(_meta.get("easter", false)):
		dialog_lines = ["АРХИВ // до-вирусная запись", "Компьютер: Доброе утро. Кофе готов. Смена спокойная.", "NOVA: ...такой оно было. до всего. запомни его таким."]
	else:
		dialog_lines = _proc_terminal_lines()
	if not nova_found:
		var _kept: Array = []
		for _ln in dialog_lines:
			if not str(_ln).begins_with("NOVA:"):
				_kept.append(_ln)
		if _kept.size() < 2:
			_kept = ["РўР•Р РњРИНАЛ", "Данные повреждены вирусом."]
		dialog_lines = _kept
	_render_dialog()

func _proc_terminal_lines() -> Array:
	var pools: Dictionary = {
		"server": [
			["РўР•Р РњРИНАЛ // серверная", "Логи хранилища затёрты. Осталась одна строка:", "'...резервный образ ядра цел. НЕ восстанавливать.'"],
			["РўР•Р РњРИНАЛ // серверная", "Диагностика: 4 узла из 5 заражены.", "NOVA: слышишь гул? это их... хор. не слушай."],
		],
		"tech": [
			["РўР•Р РњРИНАЛ // техэтаж", "Схема вентиляции мигает. Кто-то менял маршруты вручную.", "NOVA: оно перекраивает завод под себя. живьём."],
			["РўР•Р РњРИНАЛ // техэтаж", "'Если читаешь это - вентили под током. иди верхом.'", "NOVA: аккуратней с трубами. я не хочу потерять тебя здесь."],
		],
		"approach": [
			["РўР•Р РњРИНАЛ // подступ", "Красный периметр. Все двери вели сюда, к ядру.", "NOVA: почти пришли. что бы там ни было... я рядом."],
			["РўР•Р РњРИНАЛ // подступ", "'Мы пытались его выключить. Оно назвало это болью.'", "NOVA: ...ему было больно? или это оно так торгуется?"],
		],
		"core": [
			["РўР•Р РњРИНАЛ // ядро", "Здесь текст расползается сам собой.", "ЯДРО: я ЖДАЛО тебя. и её. особенно её."],
			["РўР•Р РњРИНАЛ // ядро", "> добро пожаловать домой, инженер.", "NOVA: не отвечай ему. просто не отвечай."],
		],
	}
	var pool: Array = pools.get(zone, [["РўР•Р РњРИНАЛ", "Данные повреждены вирусом."]])
	return pool[randi() % pool.size()]

func _advance_dialog() -> void:
	dialog_idx += 1
	if dialog_idx >= dialog_lines.size():
		var after := dialog_after
		dialog_after = ""
		if after == "transform":
			_begin_transform()
		else:
			state = St.PLAY
			_show_zone_banner()
	else:
		if audio: audio.sfx("blip")
		_render_dialog()

func _render_dialog() -> void:
	dlg_t0 = menu_t
	queue_redraw()

func say(t: String) -> void:
	if not nova_found:
		return
	chat_queue.append(t)

func nova_lucid(t: String) -> void:
	chat_queue.clear()
	chat_full = ""
	chat_queue.append(t)
	lucid_flash = 1.0
	if audio: audio.sfx("nova_glitch")

func _update_chatter(delta: float) -> void:
	lucid_flash = max(0.0, lucid_flash - delta)
	if chat_full == "" and not chat_queue.is_empty():
		chat_full = chat_queue.pop_front()
		chat_shown = ""; chat_char = 0.0
		if audio: audio.sfx("blip")
	if chat_full != "":
		if chat_shown.length() < chat_full.length():
			chat_char += delta * 32.0
			var n: int = min(int(chat_char), chat_full.length())
			chat_shown = chat_full.substr(0, n)
		else:
			chat_hold += delta
			if chat_hold > 2.8:
				chat_full = ""; chat_shown = ""; chat_hold = 0.0
	if state == St.PLAY and nova_found:
		idle_cd -= delta
		if idle_cd <= 0.0:
			idle_cd = randf_range(11.0, 18.0)
			if chat_full == "" and chat_queue.is_empty():
				say(_idle_line())

func _idle_line() -> String:
	if randf() < 0.22:
		var owned: Array = []
		if abilities.get("dash", false): owned.append("твой рывок стал резче. мне за тобой не угнаться.")
		if abilities.get("blast", false): owned.append("ты весь в железе теперь. пушка гудит.")
		if abilities.get("nova_hack", false): owned.append("мой импульс вербует их. мы растём, а их меньше.")
		if abilities.get("spread", false): owned.append("веером косишь толпу. красиво.")
		if not owned.is_empty():
			return owned[randi() % owned.size()]
	if is_instance_valid(player) and player.hp <= 2.0:
		var low := ["Ты весь в искрах! Найди аптечку!", "Пожалуйста, не умирай. Я больше никого не потеряю.", "Мало брони! Уходи в рывок!"]
		return low[randi() % low.size()]
	var zlines: Dictionary = {
		"reception": ["Ресепшн... тут ещё пахнет кофе.", "Отсюда всё началось. Турникеты мертвы."],
		"openspace": ["Опенспейс. Столько пустых кресел.", "Мониторы горят логотипом. Жутко."],
		"meeting": ["Переговорки. Тут любили обещать сроки.", "На доске чей-то план побега."],
		"archive": ["Архив. Бумага, пыль и старые бэкапы.", "Где-то тут история этого места."],
		"server": ["Серверная. Вентиляторы воют как живые.", "Тут его мозг. Чувствуешь гул?"],
		"tech": ["Техэтаж. Осторожно с кабелями под током.", "Трубы, пар, ржавчина. РИ Оно ближе."],
		"approach": ["Подступ к ядру. Красный свет везде.", "Ещё немного. Держись рядом."],
		"core": ["ЯДРО. Оно знает, что мы здесь.", "Дальше только Оно."],
	}
	if randf() < 0.45 and zlines.has(zone):
		var zl: Array = zlines[zone]
		return zl[randi() % zl.size()]
	var early := ["Дыши ровно. Мы справимся.", "РИди на восток. Я держу карту.", "F - мой ток. Не забывай про меня в бою."]
	var mid := ["Сигнал вируса растёт. Не нравится мне это.", "Ты слышал? ...Нет? Ладно.", "Мои сенсоры барахлят. Помехи, наверное."]
	var late := ["Х-холодно. Почему тут так холодно.", "Не отходи. НЕ. отходи. ...прости.", "Оно шепчет в моём канале. Я не слушаю.", "Я всё ещё Nova. Я всё ещё Nov-"]
	if zone_glitch.get(zone, 0.0) >= 0.55: return late[randi() % late.size()]
	if zone_glitch.get(zone, 0.0) >= 0.28: return mid[randi() % mid.size()]
	return early[randi() % early.size()]

func _room_enter_chatter() -> void:
	if state != St.PLAY or not nova_found: return
	if _is_shop_room(room_pos):
		say("Безопасно. Трать валюту с врагов - подойди к пьедесталу и коснись кнопки действия.")
	elif room_had_enemies:
		say("Осторожно, враги. Дверь заклинит, пока не зачистишь. кнопка NOVA запускает мой импульс!")

func _cleared_chatter() -> void:
	var key: String = "story_%d_%d" % [chapter, rooms_cleared]
	var beat: String = ""
	if chapter == 1 and rooms_cleared == 3:
		beat = "NOVA: Я помню этот этаж. Здесь меня собрали. Но в журнале моё имя почему-то стёрто."
	elif chapter == 1 and rooms_cleared == 7:
		beat = "NOVA: Сигнал снизу зовёт меня по серийному номеру. Оно знало, что мы придём."
	elif chapter == 2 and rooms_cleared == 2:
		beat = "NOVA: Эти кабели ведут не к ядру... они ведут ко мне. Как будто завод готовил для меня тело."
	elif chapter == 2 and rooms_cleared == 6:
		beat = "NOVA: Нашла закрытый протокол: N.O.V.A. значит «Носитель Обучающегося Вирусного Архива». Я не ремонтный юнит."
	elif chapter == 3 and rooms_cleared == 2:
		beat = "ЯДРО: вернись домой, NOVA. инженер тебе солгал, хотя сам ещё не знает об этом."
	elif chapter == 3 and rooms_cleared == 5:
		beat = "NOVA: Если я сорвусь, не стреляй сразу. Дай мне секунду вспомнить, кто я."
	if beat != "" and not event_seen.get(key, false):
		event_seen[key] = true
		say(beat)
	elif zone_glitch.get(zone, 0.0) >= 0.55:
		say("Ч-чисто. Идём. Пока я ещё я.")
	else:
		say("Чисто. Двери открыты, двигаемся дальше.")

func _glitchify(s: String) -> String:
	if glitch_level < 0.3:
		return s
	var chars := "#@%&/|01"
	var out := ""
	for i in range(s.length()):
		if randf() < glitch_level * 0.12 and s[i] != " ":
			out += chars[randi() % chars.length()]
		else:
			out += s[i]
	return out

func _start_virus() -> void:
	state = St.VIRUS
	virus = VirusScript.new()
	virus.game = self
	virus.player = player
	virus.position = Vector2(RW * TILE * 0.5, 3.0 * TILE)
	secret_boss = lore_idx >= 7
	virus.max_hp = (340.0 + rooms_cleared * 8.0) * (1.0 + ng_plus * 0.4) * (1.7 if secret_boss else 1.0)
	virus.hp = virus.max_hp
	if secret_boss and "secret" in virus:
		virus.secret = true
	world_root.add_child(virus)
	if audio: audio.play_music("boss")
	if audio: audio.sfx("virus")
	shake = 0.5
	_flash("ГЛАВНЫЙ КОМПЬЮТЕР — РИРЎРўРћР§РќРИК Р’РИРУСА")
	say("Вот оно. Уничтожь его ядро, и вирус умрёт!")

func virus_defeated() -> void:
	if is_instance_valid(virus): virus.queue_free()
	virus = null
	for b in bullets:
		if is_instance_valid(b): b.queue_free()
	bullets.clear()
	if audio: audio.sfx("explode")
	shake = 0.7
	player.hp = min(player.max_hp, player.hp + 4.0)
	state = St.DIALOG
	dialog_idx = 0
	dialog_lines = [
		"Экран компьютера гаснет. Тишина.",
		"...Получилось? Вирус стёрт. Мы сделали это.",
		"NOVA: ...стой. Что-то не так. Мои сенсоры...",
		"ЭКРАН РњРИГАЕТ: > РИРЎРўРћР§РќРИК Р’РИРУСА НЕ РЈРќРИЧТОЖЕН.",
		"ЭКРАН РњРИГАЕТ: > ОЧАГ ПЕРЕНЕСЁН В РџРћРЎР›Р•Р”РќРИЙ Р®РќРИТ: N.O.V.A.",
		"NOVA: нет. нет-нет-нет. оно всё это время было во мне?",
		"NOVA: я не удержу. прости. я так хотела довести тебя живым. п р о с т и.",
	]
	dialog_after = "transform"
	_render_dialog()

func _begin_transform() -> void:
	state = St.TRANSFORM
	tf_hold = 0.0
	nova.visible = true
	nova.menu_mode = false
	nova.infected = true
	nova.position = Vector2(RW * TILE * 0.5, 4.5 * TILE)
	nova.start_transform()
	if audio:
		audio.play_music("boss")
		audio.sfx("transform")
	shake = 0.9

func _update_transform(delta: float) -> void:
	glitch_level = min(1.0, glitch_level + delta * 0.5)
	shake = max(shake, 0.35)
	if nova.transform_done:
		tf_hold += delta
		if tf_hold > 1.2:
			_spawn_boss()

func _spawn_boss() -> void:
	state = St.BOSS
	nova.visible = false
	boss = BossScript.new()
	boss.game = self
	boss.player = player
	boss.position = Vector2(RW * TILE * 0.5, 4.0 * TILE)
	var count := 0
	for k in abilities.keys():
		if abilities[k]: count += 1
	boss.max_hp = (560.0 + count * 160.0) * (1.0 + ng_plus * 0.4) * (1.0 + rooms_cleared * 0.02)
	boss.hp = boss.max_hp
	if abilities["spread"]: boss.b_bolts += 2
	if abilities["blast"]: boss.b_charge = true
	if abilities["dash"]: boss.b_dash = true
	if abilities["nova_hack"]: boss.b_turret = true
	world_root.add_child(boss)
	shake = 0.6
	var turned: Array = []
	if abilities["dash"]: turned.append("ТВОЙ РЫВОК")
	if abilities["spread"]: turned.append("ТВОЙ ЗАЛП")
	if abilities["blast"]: turned.append("ТВОЁ РЈРЎРИР›Р•РќРИЕ")
	if abilities["nova_hack"]: turned.append("РўР’РћРИ РўРЈР Р•Р›РИ")
	if turned.is_empty():
		_flash("ОНО больше не Nova.")
	else:
		_flash("ОНА ОБРАЩАЕТ РџР РћРўРИВ ТЕБЯ: " + ", ".join(turned))

func boss_killed(lucid: bool = false) -> void:
	if state == St.WIN: return
	merciful = lucid
	ending = ("truth" if (lucid and lore_idx >= 6) else ("peace" if lucid else "grim"))
	end_t = 0.0
	end_phase = 0
	state = St.ENDING
	if is_instance_valid(boss): boss.queue_free()
	boss = null
	for b in bullets:
		if is_instance_valid(b): b.queue_free()
	bullets.clear()
	if audio:
		audio.sfx("win" if merciful else "explode"); audio.play_music("menu")
	shake = 0.8
	var cf := ConfigFile.new()
	cf.set_value("s", "ng_plus", ng_plus)
	cf.save(SAVE_PATH)
	meta_cores += rooms_cleared + (8 if merciful else 3)
	var mf := ConfigFile.new()
	mf.set_value("m", "cores", meta_cores)
	mf.save(META_PATH)

func spawn_bullet(pos: Vector2, dir: Vector2, team: String, dmg: float, col: Color, speed: float = 150.0, radius: float = 2.5):
	var b = BulletScript.new()
	b.game = self
	b.position = pos
	b.vel = dir.normalized() * speed
	b.team = team; b.dmg = dmg * (dmg_mult() if team == "player" else 1.0); b.col = col; b.radius = radius
	if team == "player":
		if weapon_mods.get("burn", false): b.burn = true
		if weapon_mods.get("freeze", false): b.freeze = true
	bullets.append(b)
	world_root.add_child(b)
	return b

func remove_bullet(b) -> void:
	bullets.erase(b)
	if is_instance_valid(b): b.queue_free()

func _combat() -> void:
	for b in bullets.duplicate():
		if not is_instance_valid(b): continue
		if b.team == "player":
			var hit := false
			for e in enemies.duplicate():
				if e != null and is_instance_valid(e) and e.hacked <= 0.0 and b.position.distance_to(e.position) <= b.radius + e.radius:
					if e.kind == "shielder" and e.shield_blocks(b.position):
						if audio: audio.sfx("ehit")
						hit = true
						break
					e.hurt(b.dmg)
					if b.burn: e.burn_t = max(e.burn_t, 2.2)
					if b.freeze: e.slow_t = max(e.slow_t, 2.0)
					_dmg_pop(e.position, b.dmg)
					if b.pierce > 0: b.pierce -= 1
					else: hit = true
					break
			if not hit and virus != null and is_instance_valid(virus):
				if b.position.distance_to(virus.position) <= b.radius + virus.radius:
					virus.hurt(b.dmg); _dmg_pop(virus.position, b.dmg); hit = true
			if not hit and boss != null and is_instance_valid(boss):
				if b.position.distance_to(boss.position) <= b.radius + boss.radius:
					boss.hurt(b.dmg); _dmg_pop(boss.position, b.dmg); hit = true
			if hit: remove_bullet(b)
		else:
			if is_instance_valid(player) and b.position.distance_to(player.position) <= b.radius + player.hy:
				note_damage_from(b.position); player.hit(b.dmg); remove_bullet(b)
	for e in enemies.duplicate():
		if e != null and is_instance_valid(e) and is_instance_valid(player):
			if e.hacked <= 0.0 and e.position.distance_to(player.position) <= e.radius + player.hy:
				note_damage_from(e.position); player.hit(e.touch_dmg)
	if boss != null and is_instance_valid(boss) and is_instance_valid(player):
		if boss.position.distance_to(player.position) <= boss.radius + player.hy:
			note_damage_from(boss.position); player.hit(1.5)

func enemy_killed(e) -> void:
	if e == null:
		return
	enemies.erase(e)
	var reward := 1
	var was_hacked := false
	if is_instance_valid(e):
		if e.kind == "boss": reward = 6
		elif e.kind == "elite": reward = 3
		was_hacked = e.hacked > 0.0
		_spawn_death_burst(e.position, _enemy_color(e.kind))
		e.queue_free()
	if not was_hacked:
		kill_combo += 1
		combo_t = 3.2
		combo_best = max(combo_best, kill_combo)
		var combo_bonus: int = 1 if kill_combo > 0 and kill_combo % 5 == 0 else 0
		currency += reward + combo_bonus
		if combo_bonus > 0:
			_flash("СЕРИЯ x%d  +1 ВАЛЮТА" % kill_combo)
			shake = max(shake, 0.18)
	if enemies.is_empty() and state == St.PLAY and room_had_enemies and not _is_cleared(room_pos):
		cleared[room_pos] = true
		rooms_cleared += 1
		if audio: audio.sfx("door")
		if audio: audio.set_intensity(false)
		_cleared_chatter()
		_save_checkpoint()

func respawn() -> void:
	# Nova shields you once per run: she takes the hit, you live at 1 HP
	if nova_found and not nova_saved and not (nova != null and nova.infected):
		nova_saved = true
		player.hp = 1.0
		player.inv = 2.0
		player.vx = 0.0; player.vy = 0.0
		shake = 0.6
		lucid_flash = 1.0
		if audio: audio.sfx("gate")
		_flash("NOVA ПРИКРЫЛА ТЕБЯ")
		nova_lucid("нет! я не дам тебе умереть. держись!")
		return
	# ROGUELIKE: no checkpoint. death is final for this run.
	deaths += 1
	death_t = 0.0
	death_pos = player.position
	state = St.DEATH
	player.visible = false
	shake = 0.8
	hitstop = max(hitstop, 0.1)
	if audio: audio.sfx("explode")
	# award meta cores for the run so far (roguelike carry)
	meta_cores += rooms_cleared
	var mf := ConfigFile.new()
	mf.set_value("m", "cores", meta_cores)
	mf.set_value("m", "lang", lang)
	mf.save(META_PATH)
	_clear_run_save()

func note_damage_from(src: Vector2) -> void:
	if shield_t > 0.0:
		return
	if is_instance_valid(player) and player.inv <= 0.0:
		var d: Vector2 = src - player.position
		if d.length() > 1.0:
			dmg_dir = d.normalized()
			dmg_flash = 1.0
			player.vx -= dmg_dir.x * 175.0
			player.vy -= dmg_dir.y * 175.0
			if nova_found and nova != null and not nova.infected and player.hp <= 2.0 and randf() < 0.5:
				if audio: audio.sfx("nova_warn")

func hazard_hit() -> void:
	if player.inv > 0.0: return
	player.hp -= 1.0
	player.inv = 0.8
	shake = 0.2
	if audio: audio.sfx("hurt")
	if player.hp <= 0.0:
		respawn()

func _save_checkpoint() -> void:
	if player == null:
		return
	var cf := ConfigFile.new()
	cf.set_value("s", "room", room_pos)
	cf.set_value("s", "nova_found", nova_found)
	cf.set_value("s", "has_key", has_key)
	cf.set_value("s", "rooms_cleared", rooms_cleared)
	cf.set_value("s", "currency", currency)
	cf.set_value("s", "ng_plus", ng_plus)
	cf.set_value("s", "abilities", abilities)
	cf.set_value("s", "collected", collected)
	cf.set_value("s", "cleared", cleared)
	cf.set_value("s", "visited", visited)
	cf.set_value("s", "puzzle", puzzle_solved)
	cf.set_value("s", "hearts", hearts_taken)
	cf.set_value("s", "gate", gate_open)
	cf.set_value("s", "bought", bought)
	cf.set_value("s", "broke_walls", broke_walls)
	cf.set_value("s", "maxhp", player.max_hp)
	cf.set_value("s", "owned", player.owned)
	cf.set_value("s", "weapon", player.weapon)
	cf.set_value("s", "event_seen", event_seen)
	cf.set_value("s", "lore_idx", lore_idx)
	cf.set_value("s", "dmg_bonus", dmg_bonus)
	cf.set_value("s", "game_time", game_time)
	cf.set_value("s", "chapter", chapter)
	cf.set_value("s", "chapter_seed", chapter_seed)
	cf.save(SAVE_PATH)
	has_save = true
	save_flash = 1.6

func _continue() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		_begin_play(); return
	if audio: audio.sfx("select")
	abilities = cf.get_value("s", "abilities", abilities)
	collected = cf.get_value("s", "collected", {})
	cleared = cf.get_value("s", "cleared", {})
	visited = cf.get_value("s", "visited", {})
	puzzle_solved = cf.get_value("s", "puzzle", {})
	hearts_taken = cf.get_value("s", "hearts", {})
	gate_open = cf.get_value("s", "gate", {})
	bought = cf.get_value("s", "bought", {})
	broke_walls = cf.get_value("s", "broke_walls", {})
	has_key = cf.get_value("s", "has_key", false)
	rooms_cleared = cf.get_value("s", "rooms_cleared", 0)
	currency = cf.get_value("s", "currency", 0)
	ng_plus = cf.get_value("s", "ng_plus", 0)
	nova_found = cf.get_value("s", "nova_found", false)
	event_seen = cf.get_value("s", "event_seen", {})
	lore_idx = cf.get_value("s", "lore_idx", 0)
	dmg_bonus = cf.get_value("s", "dmg_bonus", 0.0)
	game_time = cf.get_value("s", "game_time", 0.0)
	player.visible = true
	player.max_hp = cf.get_value("s", "maxhp", 6.0)
	player.hp = player.max_hp
	player.owned = cf.get_value("s", "owned", [true, false, false])
	player.weapon = cf.get_value("s", "weapon", 0)
	nova.visible = nova_found
	nova.menu_mode = false
	nova.infected = false
	state = St.PLAY
	chapter = cf.get_value("s", "chapter", 1)
	chapter_seed = cf.get_value("s", "chapter_seed", 0)
	if chapter > 1:
		rooms = RoomData.chapter_map(chapter, chapter_seed)
	var rp = cf.get_value("s", "room", Vector2i(0, 0))
	_load_room(rp, "start")
	_flash("С возвращением. Зачищено комнат: " + str(rooms_cleared) + "  Зона: " + zone_name.get(zone, ""))
	if nova_found:
		say("Ты снова тут. Я не уходила. Продолжаем с того же места.")

func _process(delta: float) -> void:
	menu_t += delta
	bg_scroll += delta * 6.0
	shake = max(0.0, shake - delta)
	save_flash = max(0.0, save_flash - delta)
	chapter_banner_t = max(0.0, chapter_banner_t - delta)
	room_fade = max(0.0, room_fade - delta * 5.0)
	dmg_flash = max(0.0, dmg_flash - delta * 2.2)
	hitstop = max(0.0, hitstop - delta)
	item_cd = max(0.0, item_cd - delta)
	death_flash = max(0.0, death_flash - delta)
	combo_t = max(0.0, combo_t - delta)
	if combo_t <= 0.0: kill_combo = 0
	if state == St.WIN: win_t += delta
	item2_cd = max(0.0, item2_cd - delta)
	shield_t = max(0.0, shield_t - delta)
	if shield_t > 0.0 and is_instance_valid(player): player.inv = max(player.inv, 0.12)
	if state == St.PLAY or state == St.VIRUS or state == St.BOSS or state == St.BOSS_INTRO or state == St.DIALOG or state == St.CHOICE:
		var _mtop: bool = (state == St.DIALOG or state == St.CHOICE)
		if is_instance_valid(player): player.visible = not _mtop
		if is_instance_valid(nova): nova.visible = (not _mtop) and nova_found and not nova.infected
		if boss != null and is_instance_valid(boss): boss.visible = not _mtop
		if virus != null and is_instance_valid(virus): virus.visible = not _mtop
		for _e in enemies:
			if is_instance_valid(_e): _e.visible = not _mtop
		for _b in bullets:
			if is_instance_valid(_b): _b.visible = not _mtop
	core_glitch_t = max(0.0, core_glitch_t - delta)
	if state == St.PLAY and zone == "core" and core_glitch_t <= 0.0:
		core_glitch_cd -= delta
		if core_glitch_cd <= 0.0:
			core_glitch_cd = randf_range(7.0, 12.0)
			core_glitch_kind = randi() % 2
			core_glitch_t = 2.6
			if audio: audio.sfx("glitch")
			shake = max(shake, 0.35)
			_flash("ЯДРО ИСКАЖАЕТ РЕАЛЬНОСТЬ")
	if audio: audio.set_duck(state == St.DIALOG or state == St.BOSS_INTRO or state == St.CHOICE)
	laser_t += delta
	laser_on = fmod(laser_t, 1.5) < 0.85
	if state == St.CHOICE: choice_t += delta

	match state:
		St.BOOT_ENGINE:
			boot_t += delta
			if boot_t > 2.3: state = St.BOOT_LOGO; boot_t = 0.0
		St.BOOT_LOGO:
			boot_t += delta
			if boot_t > 2.4: _show_menu()
		St.INTRO:
			cut_t += delta
			if cut_t > 4.5:
				cut_t = 0.0; cut_phase += 1
				if cut_phase >= 4: _begin_play()
		St.TRANSFORM:
			_update_transform(delta)
		St.BOSS_INTRO:
			boss_intro_t += delta
			if boss_intro_t > 3.4:
				_end_boss_intro()
		St.NOVA_CUT:
			nova_cut_t += delta
			if nova_cut_t > 5.0:
				_nova_dialog()
		St.DEATH:
			death_t += delta
			if death_t > 5.5:
				get_tree().reload_current_scene()
		St.ENDING:
			end_t += delta
			if end_t > 24.0:
				_clear_run_save(); get_tree().reload_current_scene()

	if start_anim > 0.0:
		start_anim = max(0.0, start_anim - delta)

	if is_active():
		game_time += delta
		_combat()
		_try_transition()
		try_collect()
		_update_chatter(delta)
		_laser_damage()
		_update_wave_spawns(delta)

	for d in dmg_nums:
		d.t += delta
		d.y -= delta * 14.0
	if dmg_nums.size() > 0:
		dmg_nums = dmg_nums.filter(func(x): return x.t < 0.7)
	for pt in parts:
		pt.t += delta
		pt.x += pt.vx * delta
		pt.y += pt.vy * delta
		pt.vx *= (1.0 - delta * 3.0)
		pt.vy *= (1.0 - delta * 3.0)
	if parts.size() > 0:
		parts = parts.filter(func(x): return x.t < x.life)
	var _sk: float = shake * (0.28 if reduce_shake else 1.0)
	var sx := 0.0; var sy := 0.0
	if _sk > 0.0:
		sx = randf_range(-1.0, 1.0) * _sk * 3.0
		sy = randf_range(-1.0, 1.0) * _sk * 3.0
	shake_px = Vector2(sx, sy)
	_update_camera(delta)
	_update_hud()
	queue_redraw()

func _cam_target() -> Vector2:
	var vw: float = COLS * TILE / zoom
	var vh: float = ROWS * TILE / zoom
	var rw: float = RW * TILE
	var rh: float = RH * TILE
	var tx: float = 0.0
	var ty: float = 0.0
	if is_instance_valid(player):
		tx = player.position.x - vw * 0.5
		ty = player.position.y - vh * 0.5
	if rw <= vw: tx = (rw - vw) * 0.5
	else: tx = clamp(tx, 0.0, rw - vw)
	if rh <= vh: ty = (rh - vh) * 0.5
	else: ty = clamp(ty, 0.0, rh - vh)
	return Vector2(tx, ty)

func _update_camera(delta: float) -> void:
	zoom = lerp(zoom, room_zoom, clamp(delta * 3.5, 0.0, 1.0))
	cam = cam.lerp(_cam_target(), clamp(delta * 9.0, 0.0, 1.0))
	if world_root != null:
		world_root.position = -cam * zoom + shake_px
		world_root.scale = Vector2(zoom, zoom)

func _snap_camera() -> void:
	zoom = room_zoom
	cam = _cam_target()
	if world_root != null:
		world_root.position = -cam * zoom
		world_root.scale = Vector2(zoom, zoom)

func world_mouse() -> Vector2:
	if world_root != null:
		return world_root.get_local_mouse_position()
	return get_local_mouse_position()

func _update_wave_spawns(delta: float) -> void:
	if wave_queue.is_empty():
		return
	wave_cd -= delta
	if wave_cd > 0.0:
		return
	var batch: int = 1 + (1 if difficulty >= 2 else 0)
	for i in range(batch):
		if wave_queue.is_empty():
			break
		var sp: Dictionary = wave_queue.pop_front()
		_spawn_enemy(sp["px"], sp["kind"])
	wave_cd = 1.8
	if audio: audio.sfx("blip")

func _laser_damage() -> void:
	if not laser_on:
		return
	var tx := int(floor(player.position.x / TILE))
	var ty := int(floor(player.position.y / TILE))
	if tile_at(tx, ty) == "L":
		hazard_hit()
	# lasers slice enemies standing in them too - use the room as a trap
	for e in enemies.duplicate():
		if e != null and is_instance_valid(e) and e.hacked <= 0.0:
			var ex := int(floor(e.position.x / TILE))
			var ey := int(floor(e.position.y / TILE))
			if tile_at(ex, ey) == "L":
				e.hurt(0.6)

func _update_hud() -> void:
	if state == St.BOOT_ENGINE or state == St.BOOT_LOGO or state == St.MENU or state == St.INTRO:
		lbl_top.text = ""; lbl_boss.visible = false
		return
	if not is_instance_valid(player): return
	var ups := ""
	if has_key: ups += "КЛЮЧ "
	var hp_i := int(ceil(player.hp))
	var hearts := str(hp_i) + "/" + str(int(player.max_hp))
	var ftext := ""
	if nova_found:
		if nova.infected: ftext = "   F —"
		elif nova.pulse_cd > 0.0: ftext = "   F " + str(int(ceil(nova.pulse_cd))) + "с"
		else: ftext = "   F готов"
	var ngtxt := ("  NG+" + str(ng_plus)) if ng_plus > 0 else ""
	var itxt := ("   граната" if item_cd <= 0.0 else "   R " + str(int(ceil(item_cd))) + "с")
	var gtxt := ("   щит" if item2_cd <= 0.0 else "   G " + str(int(ceil(item2_cd))) + "с")
	lbl_top.text = "HP " + hearts + "   $" + str(currency) + "   " + ups + ftext + itxt + gtxt + ngtxt
	var bo = boss if boss != null else virus
	if (state == St.BOSS or state == St.VIRUS) and bo != null and is_instance_valid(bo):
		var frac: float = clamp(bo.hp / bo.max_hp, 0.0, 1.0)
		var bar := ""
		for i in range(20):
			bar += ("#" if float(i) / 20.0 < frac else ".")
		var nm := "Р’РИРУС-КОМПЬЮТЕР" if state == St.VIRUS else "ЗАРАЖЁННАЯ NOVA"
		lbl_boss.text = nm + "  [" + bar + "]"
		lbl_boss.visible = true
	else:
		lbl_boss.visible = false

func mobile_action(action: String) -> void:
	if action == "map" and (state == St.PLAY or state == St.VIRUS or state == St.BOSS):
		map_open = not map_open; return
	if action == "start" and state == St.MENU:
		_menu_start(); return
	if action == "continue":
		match state:
			St.BOOT_ENGINE, St.BOOT_LOGO: _show_menu()
			St.INTRO:
				cut_phase += 1; cut_t = 0.0
				if cut_phase >= 4: _begin_play()
			St.BOSS_INTRO: _end_boss_intro()
			St.DIALOG: _advance_dialog()
			St.NOVA_CUT: _nova_dialog()
			St.DEATH:
				if death_t > 1.2: get_tree().reload_current_scene()
			St.ENDING:
				if end_t < 7.0: end_t = 7.0
				else: _clear_run_save(); get_tree().reload_current_scene()
		return
	if state == St.CHOICE and action.begins_with("choice"):
		_pick_choice(clampi(int(action.right(1)) - 1, 0, 2)); return
	if state == St.PLAY or state == St.VIRUS or state == St.BOSS:
		match action:
			"nova": nova_pulse()
			"use": interact()
			"weapon": player.cycle_weapon()
			"item": use_active_item()
			"shield": use_item2()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		_joy_button(event.button_index)
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k: int = event.keycode
	if (k == KEY_TAB or (k == KEY_M and not paused)) and (state == St.PLAY or state == St.VIRUS or state == St.BOSS):
		map_open = not map_open
		if audio: audio.sfx("select")
		return
	if map_open:
		if k == KEY_ESCAPE or k == KEY_TAB or k == KEY_M: map_open = false
		return
	if k == KEY_ESCAPE and (state == St.PLAY or state == St.VIRUS or state == St.BOSS):
		paused = not paused
		if audio: audio.sfx("select")
		return
	if paused:
		if rebind_idx >= 0:
			_capture_rebind(k)
			return
		if k == KEY_B:
			rebind_idx = 0
			if audio: audio.sfx("select")
			return
		if k == KEY_M and audio: audio.toggle_music(not audio.music_on)
		elif k == KEY_N and audio: audio.sfx_on = not audio.sfx_on
		elif k == KEY_BRACKETLEFT and audio: audio.set_master(audio.master - 0.1)
		elif k == KEY_BRACKETRIGHT and audio: audio.set_master(audio.master + 0.1)
		elif k == KEY_K:
			reduce_shake = not reduce_shake
			if audio: audio.sfx("select")
		elif k == KEY_L:
			lang = 1 - lang
			_save_lang()
			if audio: audio.sfx("select")
		elif k == KEY_Q: get_tree().reload_current_scene()
		return
	match state:
		St.BOOT_ENGINE, St.BOOT_LOGO:
			if k == KEY_SPACE or k == KEY_ENTER: _show_menu()
		St.MENU:
			if seed_entry: _seed_key(k)
			elif k == KEY_SPACE or k == KEY_ENTER: _menu_start()
			elif k == KEY_C and has_save: _continue()
			elif k == KEY_S: seed_entry = true; seed_input = ""; has_custom_seed = false
			elif k == KEY_L:
				lang = 1 - lang
				_save_lang()
				if audio: audio.sfx("blip")
			elif k == KEY_1 or k == KEY_KP_1: _set_diff(0)
			elif k == KEY_2 or k == KEY_KP_2: _set_diff(1)
			elif k == KEY_3 or k == KEY_KP_3: _set_diff(2)
			elif k == KEY_TAB:
				pclass = (pclass + 1) % 3
				if audio: audio.sfx("blip")
		St.INTRO:
			if k == KEY_SPACE or k == KEY_ENTER:
				cut_phase += 1; cut_t = 0.0
				if cut_phase >= 4: _begin_play()
		St.BOSS_INTRO:
			if k == KEY_E or k == KEY_ENTER or k == KEY_SPACE: _end_boss_intro()
		St.DIALOG:
			if k == KEY_E or k == KEY_ENTER or k == KEY_SPACE: _advance_dialog()
		St.CHOICE:
			if k == KEY_1 or k == KEY_KP_1: _pick_choice(0)
			elif k == KEY_2 or k == KEY_KP_2: _pick_choice(1)
			elif k == KEY_3 or k == KEY_KP_3: _pick_choice(2)
			elif k == KEY_R: _reroll_choice()
		St.DEATH:
			if k == KEY_SPACE or k == KEY_ENTER or k == KEY_R:
				if death_t > 1.2: get_tree().reload_current_scene()
		St.NOVA_CUT:
			if k == KEY_SPACE or k == KEY_ENTER or k == key_interact: _nova_dialog()
		St.ENDING:
			if k == KEY_SPACE or k == KEY_ENTER:
				if end_t < 7.0: end_t = 7.0
				else: _clear_run_save(); get_tree().reload_current_scene()
		St.WIN:
			if k == KEY_R: _clear_run_save(); get_tree().reload_current_scene()
			elif k == KEY_N: ng_plus += 1; _clear_run_save(); get_tree().reload_current_scene()
		St.PLAY:
			if k == key_interact: interact()
			elif k == key_weapon: player.cycle_weapon()
			elif k == key_pulse: nova_pulse()
			elif k == key_item: use_active_item()
			elif k == key_shield: use_item2()
		St.VIRUS, St.BOSS:
			if k == key_item: use_active_item()
			elif k == key_shield: use_item2()

func _clear_run_save() -> void:
	var cf := ConfigFile.new()
	cf.set_value("s", "ng_plus", ng_plus)
	cf.save(SAVE_PATH)

func _menu_start() -> void:
	if audio: audio.sfx("select")
	start_anim = 0.8
	state = St.INTRO
	cut_phase = 0; cut_t = 0.0

func _begin_play() -> void:
	player.visible = true
	nova.visible = false
	nova.menu_mode = false
	nova_found = false
	nova_saved = false
	secret_boss = false
	weapon_mods = {"burn": false, "freeze": false, "bounce": false}
	chapter = 1
	if has_custom_seed and seed_input.length() > 0:
		chapter_seed = int(seed_input) & 0x7fffffff
	else:
		chapter_seed = randi()
	rooms = RoomData.chapter_map(1, chapter_seed)
	state = St.PLAY
	if meta_cores >= 15: player.max_hp += 2.0
	if meta_cores >= 35: player.owned[1] = true
	if meta_cores >= 60: abilities["dash"] = true
	if meta_cores >= 90: abilities["blast"] = true
	if meta_cores >= 130: player.max_hp += 2.0
	if meta_cores >= 180: player.owned[2] = true
	player.speed_mult = 1.0
	match pclass:
		1:
			player.speed_mult = 1.28; player.max_hp = max(3.0, player.max_hp - 1.0)
		2:
			player.speed_mult = 0.88; player.max_hp += 3.0
	player.hp = player.max_hp
	if difficulty == 0:
		player.max_hp += 2.0; player.hp = player.max_hp
	elif difficulty == 2:
		player.max_hp = max(3.0, player.max_hp - 1.0); player.hp = player.max_hp
	_load_room(Vector2i(0, 0), "start")
	_flash("Левый стик: движение. Правый стик: прицел и огонь")
	_show_chapter_banner("ГЛАВА 1", "ЗАВОД РОБОТОВ")

func _flash(t: String) -> void:
	_banner_text = t
	_banner_a = 1.0

func _show_zone_banner() -> void:
	_banner_text = zone_name.get(zone, "")
	_banner_a = 1.0

func _is_shop_room(pos: Vector2i) -> bool:
	return bool((rooms.get(pos, {}) as Dictionary).get("shop", RoomData.is_shop(pos)))

func _try_descend() -> void:
	if not _is_cleared(room_pos):
		if audio: audio.sfx("deny")
		_flash("Сначала зачисти зал")
		say("Ещё рано. Добей всё здесь, потом вниз.")
		return
	_next_chapter()

func _next_chapter() -> void:
	chapter += 1
	rooms = RoomData.chapter_map(chapter, chapter_seed)
	visited.clear(); cleared.clear(); puzzle_solved.clear(); gate_open.clear()
	has_key = false
	if audio: audio.sfx("gate")
	shake = 0.6
	_load_room(Vector2i(0, 0), "start")
	state = St.DIALOG
	dialog_idx = 0
	dialog_after = ""
	if chapter == 2:
		dialog_lines = ["СИСТЕМА: ЛИФТ // УРОВЕНЬ -07", "Стальные тросы стонут. На стенах лифта проступают старые детские рисунки роботов.", "NOVA: Я видела их раньше... хотя меня собрали уже после эвакуации.", "СИСТЕМА: ОБНАРУЖЕН НЕИЗВЕСТНЫЙ ПАССАЖИР: N.O.V.A.", "NOVA: Неизвестный? Тогда почему система знает моё имя?"]
	elif chapter == 3:
		dialog_lines = ["СИСТЕМА: ЛИФТ // ЯДРО", "Лифт останавливается раньше времени. Двери раскрываются в живой кабельный тоннель.", "ЯДРО: ДОБРО ПОЖАЛОВАТЬ ДОМОЙ, ДОЧЬ.", "NOVA: Не слушай. Я не его дочь... правда?", "NOVA: Если со мной что-то случится, найди в терминалах протокол MERCY. Пообещай."]
	else:
		dialog_lines = ["ГЛАВА " + str(chapter), "Ниже. Ещё ниже.", "NOVA: РИдём. Назад дороги нет."]
	if chapter == 2:
		_show_chapter_banner("ГЛАВА 2", "СПУСК В РўР•РҐРќРИР§Р•РЎРљРИЙ УРОВЕНЬ")
	elif chapter == 3:
		_show_chapter_banner("ГЛАВА 3", "РџРћР“Р РЈР–Р•РќРИЕ В ЯДРО")
	else:
		_show_chapter_banner("ГЛАВА " + str(chapter), "РќРИЖЕ РИ РќРИЖЕ")
	_render_dialog()

func _draw_descent(r: Rect2) -> void:
	var ready: bool = _is_cleared(room_pos)
	draw_rect(r, Color(0.04, 0.05, 0.08), true)
	draw_rect(Rect2(r.position.x + 2.0, r.position.y + 2.0, TILE - 4.0, TILE - 4.0), Color(0.02, 0.02, 0.03), true)
	var glow: float = 0.5 + 0.5 * sin(menu_t * 3.0)
	var col: Color = (Color(0.4, 1.0, 0.7) if ready else Color(0.6, 0.35, 0.35))
	col.a = ((0.35 + 0.5 * glow) if ready else 0.5)
	var cx: float = r.position.x + TILE * 0.5
	for i in range(3):
		var yy: float = r.position.y + 4.0 + float(i) * 4.0
		draw_line(Vector2(cx - 4.0, yy), Vector2(cx, yy + 3.0), col, 1.4)
		draw_line(Vector2(cx, yy + 3.0), Vector2(cx + 4.0, yy), col, 1.4)

func _show_menu() -> void:
	state = St.MENU
	menu_t = 0.0
	has_save = FileAccess.file_exists(SAVE_PATH)
	# the menu centrepiece is drawn by CutScenes.draw_nova; keep the real
	# Nova node hidden so we do not render two of her on the title/intro
	nova.visible = false
	nova.menu_mode = true
	nova.infected = false
	nova.position = Vector2(COLS * TILE * 0.5, ROWS * TILE * 0.46)
	if audio: audio.play_music("menu")

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	lbl_top = _mk(10, HORIZONTAL_ALIGNMENT_LEFT); lbl_top.position = Vector2(4, 3)
	lbl_top.add_theme_constant_override("outline_size", 3)
	lbl_top.add_theme_color_override("font_outline_color", Color(0, 0, 0.02, 0.95))
	lbl_boss = _mk(9, HORIZONTAL_ALIGNMENT_CENTER); lbl_boss.position = Vector2(0, 14); lbl_boss.size = Vector2(COLS*TILE, 12); lbl_boss.visible = false
	lbl_boss.add_theme_constant_override("outline_size", 3)
	lbl_boss.add_theme_color_override("font_outline_color", Color(0, 0, 0.02, 0.95))

func _mk(fs: int, align: int) -> Label:
	var l := Label.new()
	if font != null: l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	l.horizontal_alignment = align
	ui.add_child(l)
	return l

func _draw() -> void:
	match state:
		St.BOOT_ENGINE: CutScenes.boot_engine(self)
		St.BOOT_LOGO: CutScenes.boot_logo(self)
		St.MENU: CutScenes.menu(self)
		St.INTRO: CutScenes.intro(self)
		_: _draw_world()
	if state == St.PLAY or state == St.VIRUS or state == St.BOSS:
		draw_set_transform(-cam * zoom + shake_px, 0.0, Vector2(zoom, zoom))
		_draw_dmg_nums()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_draw_ability_icons()
		_draw_combo()
		_draw_savemark()
	if state == St.MENU:
		_draw_diff_label()
	if start_anim > 0.0:
		var a: float = start_anim / 0.8
		draw_rect(Rect2(0, ROWS*TILE * (1.0 - a), COLS*TILE, ROWS*TILE), Color(0.02,0.03,0.05, a))
	if paused:
		_draw_pause()
	if map_open:
		_draw_fullmap()

func _dmg_pop(pos: Vector2, val: float) -> void:
	var v: int = int(round(val))
	if v <= 0: return
	parts.append({"x": pos.x, "y": pos.y, "vx": 0.0, "vy": 0.0, "t": 0.0, "life": 0.18, "col": Color(1.0, 1.0, 0.8), "r": 3.0, "ring": true})
	dmg_nums.append({"x": pos.x + randf_range(-3.0, 3.0), "y": pos.y - 6.0, "val": v, "t": 0.0, "crit": val >= 3.0})
	if dmg_nums.size() > 40: dmg_nums.pop_front()

func _draw_dmg_nums() -> void:
	for d in dmg_nums:
		var a: float = clamp(1.0 - d.t / 0.7, 0.0, 1.0)
		var col: Color = Color(1.0, 0.55, 0.3, a) if d.crit else Color(1.0, 0.92, 0.5, a)
		var fs: int = 9 if d.crit else 7
		draw_string(font, Vector2(d.x - 4.0, d.y), str(d.val), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

func _draw_combo() -> void:
	if kill_combo < 2 or combo_t <= 0.0:
		return
	var W: float = COLS * TILE
	var hot: float = clamp(float(kill_combo - 2) / 8.0, 0.0, 1.0)
	var col: Color = Color(0.45, 0.9, 1.0).lerp(Color(1.0, 0.42, 0.24), hot)
	var x: float = W - 55.0
	draw_string(font, Vector2(x, 31), "СЕРИЯ  x" + str(kill_combo), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
	draw_rect(Rect2(x, 34, 46.0, 2.0), Color(0.08,0.12,0.16,0.9))
	draw_rect(Rect2(x, 34, 46.0 * combo_t / 3.2, 2.0), col)

func _draw_ability_icons() -> void:
	if not is_instance_valid(player): return
	var H: float = ROWS * TILE
	var icons: Array = []
	if abilities["dash"]: icons.append(["РЫВ", Color(0.5, 0.85, 1.0)])
	if abilities["spread"]: icons.append(["ЗАЛП", Color(1.0, 0.8, 0.4)])
	if abilities["blast"]: icons.append(["РЈРЎРИЛ", Color(1.0, 0.55, 0.55)])
	if abilities["nova_hack"] and nova_found: icons.append(["ВЗЛ", Color(0.6, 1.0, 0.7)])
	var x: float = 4.0
	var y: float = H - 11.0
	for ic in icons:
		draw_rect(Rect2(x, y, 24.0, 9.0), Color(0.05, 0.07, 0.10, 0.72))
		draw_rect(Rect2(x, y, 24.0, 9.0), ic[1], false, 1.0)
		draw_string(font, Vector2(x + 2.0, y + 7.0), ic[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 6, ic[1])
		x += 27.0

func _draw_diff_label() -> void:
	var W: float = COLS * TILE; var H: float = ROWS * TILE
	var names: Array = ["ЛЕГКО", "НОРМАЛЬНО", "ХАРДКОР"]
	var t: String = "Сложность [1/2/3]: " + names[difficulty]
	draw_string(font, Vector2(W * 0.5 - 62.0, H - 7.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.7, 0.85, 1.0))
	var seedtxt: String
	if seed_entry:
		seedtxt = "РЎРИД: " + seed_input + ("_" if int(menu_t * 2.0) % 2 == 0 else " ") + "   [Enter/Esc]"
	elif has_custom_seed and seed_input.length() > 0:
		seedtxt = "РЎРИД: " + seed_input + "   (S - изменить)"
	else:
		seedtxt = "S - ввести свой сид"
	draw_string(font, Vector2(6.0, 12.0), seedtxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, (Color(1.0, 0.95, 0.5) if seed_entry else Color(0.55, 0.72, 0.82)))
	var cnames: Array = ["БАЛАНС", "СКОРОХОД", "ТАНК"]
	draw_string(font, Vector2(W - 92.0, 12.0), "TAB: " + String(cnames[pclass]), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.7,0.9,1.0))
	draw_string(font, Vector2(6.0, 22.0), "ЯДРА: " + str(meta_cores), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.6,1.0,0.7))
	if meta_cores >= 15:
		draw_string(font, Vector2(6.0, 31.0), "старт-бонусы разблокированы", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.5,0.8,0.6))

func _set_diff(d: int) -> void:
	difficulty = d
	if audio: audio.sfx("blip")

func _capture_rebind(k: int) -> void:
	if k == KEY_ESCAPE:
		rebind_idx = -1
		return
	match rebind_idx:
		0: key_interact = k
		1: key_weapon = k
		2: key_pulse = k
		3: key_item = k
		4: key_shield = k
	rebind_idx += 1
	if audio: audio.sfx("blip")
	if rebind_idx > 4:
		rebind_idx = -1
		_save_lang()

func _key_name(k: int) -> String:
	return OS.get_keycode_string(k)

func _draw_pause() -> void:
	var W: float = COLS*TILE; var H: float = ROWS*TILE
	draw_rect(Rect2(0,0,W,H), Color(0.02,0.03,0.05,0.88))
	CutScenes.ctext(self, "ПАУЗА", W*0.5, 22.0, 16, Color(0.8,0.95,1.0))
	# left column: settings
	var mus := "вкл" if (audio and audio.music_on) else "выкл"
	var sfxs := "вкл" if (audio and audio.sfx_on) else "выкл"
	var vol := int((audio.master if audio else 0.0) * 100)
	var rsh := "вкл" if reduce_shake else "выкл"
	var lx: float = 10.0
	var ly: float = 40.0
	draw_string(font, Vector2(lx, ly), "НАСТРОЙКИ", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.6,0.9,1.0))
	var rows := [
		"M  музыка: " + mus,
		"N  звуки: " + sfxs,
		"[ ]  громкость: " + str(vol) + "%",
		"K  меньше тряски: " + rsh,
		T("L  язык: РУ", "L  language: EN"),
		T("Q  выйти в меню", "Q  quit to menu"),
		T("Esc  продолжить", "Esc  resume"),
	]
	for i in range(rows.size()):
		draw_string(font, Vector2(lx, ly + 14.0 + i*12.0), String(rows[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.78,0.86,0.95))
	# run stats
	var sy: float = ly + 14.0 + rows.size()*12.0 + 6.0
	draw_string(font, Vector2(lx, sy), "Глава " + str(chapter) + "   Сид " + str(chapter_seed), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.6,0.75,0.85))
	draw_string(font, Vector2(lx, sy + 10.0), "Комнат: " + str(rooms_cleared) + "   Смертей: " + str(deaths), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.6,0.75,0.85))
	# right column: chapter map
	var mx0: float = W*0.56
	var my0: float = 44.0
	draw_string(font, Vector2(mx0, my0 - 4.0), "КАРТА ГЛАВЫ", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.6,0.9,1.0))
	var cell := 6.0; var gp := 2.4
	var minx := 999; var maxx := -999; var miny := 999; var maxy := -999
	for pos in rooms.keys():
		minx = mini(minx, pos.x); maxx = maxi(maxx, pos.x)
		miny = mini(miny, pos.y); maxy = maxi(maxy, pos.y)
	var step: float = cell + gp
	var span_x: float = float(maxx - minx + 1) * step
	var bx0: float = mx0 + maxf(0.0, (W*0.4 - span_x) * 0.5)
	var by0: float = my0 + 10.0
	for pos in rooms.keys():
		if not visited.get(pos, false): continue
		var ax: float = bx0 + (pos.x - minx)*step + cell*0.5
		var ay: float = by0 + (pos.y - miny)*step + cell*0.5
		for dd in [Vector2i(1,0), Vector2i(0,1)]:
			var nb: Vector2i = pos + dd
			if rooms.has(nb) and visited.get(nb, false):
				var nnx: float = bx0 + (nb.x - minx)*step + cell*0.5
				var nny: float = by0 + (nb.y - miny)*step + cell*0.5
				draw_line(Vector2(ax,ay), Vector2(nnx,nny), Color(0.5,0.62,0.72,0.6), 1.0)
	for pos in rooms.keys():
		var rx: float = bx0 + (pos.x - minx)*step
		var ry: float = by0 + (pos.y - miny)*step
		var col := Color(0.18,0.22,0.28,0.7)
		if visited.get(pos, false):
			col = pal.get(rooms[pos]["style"], pal["clean"])["ac"]; col.a = 0.85
		draw_rect(Rect2(rx, ry, cell, cell), col)
		if visited.get(pos, false):
			var info2: Dictionary = rooms[pos]
			if bool(info2.get("shop", false)):
				draw_rect(Rect2(rx+1.5, ry+1.5, cell-3.0, cell-3.0), Color(0.4,1.0,0.6,0.95))
			elif info2.has("boss") or bool(info2.get("descent", false)):
				draw_rect(Rect2(rx+1.5, ry+1.5, cell-3.0, cell-3.0), Color(1.0,0.35,0.35,0.95))
			elif bool(info2.get("easter", false)):
				draw_rect(Rect2(rx+2.0, ry+2.0, cell-4.0, cell-4.0), Color(1.0,0.9,0.4,0.9))
		if pos == room_pos:
			draw_rect(Rect2(rx-1.0, ry-1.0, cell+2.0, cell+2.0), Color(1,1,1,0.95), false, 1.0)
	# legend
	var leg_y: float = by0 + float(maxy - miny + 1) * step + 12.0
	draw_rect(Rect2(mx0, leg_y, 5.0, 5.0), Color(0.4,1.0,0.6,0.95))
	draw_string(font, Vector2(mx0+8.0, leg_y+5.0), "магазин", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.7,0.85,0.8))
	draw_rect(Rect2(mx0, leg_y+10.0, 5.0, 5.0), Color(1.0,0.35,0.35,0.95))
	draw_string(font, Vector2(mx0+8.0, leg_y+15.0), "босс", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.9,0.75,0.75))
	draw_rect(Rect2(mx0, leg_y+20.0, 5.0, 5.0), Color(1.0,0.9,0.4,0.9))
	draw_string(font, Vector2(mx0+8.0, leg_y+25.0), "секрет", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.9,0.85,0.6))
	# collected abilities row
	var ab: Array = []
	if abilities.get("dash", false): ab.append("РЫВОК")
	if abilities.get("spread", false): ab.append("ЗАЛП")
	if abilities.get("blast", false): ab.append("УСИЛ")
	if abilities.get("nova_hack", false): ab.append("ВЗЛОМ")
	if not ab.is_empty():
		draw_string(font, Vector2(mx0, leg_y+40.0), T("Улучшения: ", "Upgrades: ") + ", ".join(ab), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.7,0.9,1.0))
	# controls / rebind block
	var cyy: float = leg_y + 54.0
	draw_string(font, Vector2(mx0, cyy), T("СЕНСОРНОЕ УПРАВЛЕНИЕ (шестерёнка на экране)", "TOUCH CONTROLS (use the gear icon)"), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6,0.9,1.0))
	var acts := [T("действие", "action"), T("оружие", "weapon"), "Nova", T("граната", "grenade"), T("щит", "shield")]
	var keys := [key_interact, key_weapon, key_pulse, key_item, key_shield]
	for i in range(acts.size()):
		var hl: bool = rebind_idx == i
		var txt: String = String(acts[i]) + ": " + (T("[жми...]", "[press...]") if hl else _key_name(keys[i]))
		draw_string(font, Vector2(mx0, cyy + 11.0 + i*10.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, (Color(1.0,0.9,0.4) if hl else Color(0.75,0.85,0.95)))

func _draw_fullmap() -> void:
	var W: float = COLS*TILE; var H: float = ROWS*TILE
	draw_rect(Rect2(0,0,W,H), Color(0.02,0.03,0.06,0.94))
	CutScenes.ctext(self, T("КАРТА ГЛАВЫ","CHAPTER MAP"), W*0.5, 20.0, 15, Color(0.8,0.95,1.0))
	var minx := 999; var maxx := -999; var miny := 999; var maxy := -999
	for pos in rooms.keys():
		minx = mini(minx, pos.x); maxx = maxi(maxx, pos.x)
		miny = mini(miny, pos.y); maxy = maxi(maxy, pos.y)
	if maxx < minx:
		return
	var cols_n: int = maxx - minx + 1
	var rows_n: int = maxy - miny + 1
	var area_x: float = 16.0
	var area_y: float = 34.0
	var area_w: float = W - 32.0
	var area_h: float = H - 74.0
	var step: float = minf(area_w / float(cols_n), area_h / float(rows_n))
	step = clampf(step, 6.0, 34.0)
	var cell: float = step * 0.82
	var gx0: float = area_x + (area_w - step*cols_n) * 0.5
	var gy0: float = area_y + (area_h - step*rows_n) * 0.5
	for pos in rooms.keys():
		if not visited.get(pos, false): continue
		var ax: float = gx0 + (pos.x - minx)*step + cell*0.5
		var ay: float = gy0 + (pos.y - miny)*step + cell*0.5
		for dd in [Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0), Vector2i(0,-1)]:
			var nb: Vector2i = pos + dd
			if rooms.has(nb):
				var seen: bool = visited.get(nb, false)
				var nnx: float = gx0 + (nb.x - minx)*step + cell*0.5
				var nny: float = gy0 + (nb.y - miny)*step + cell*0.5
				var lc: Color = Color(0.5,0.62,0.72,0.55) if seen else Color(0.4,0.45,0.5,0.22)
				draw_line(Vector2(ax,ay), Vector2(nnx,nny), lc, 1.5)
	for pos in rooms.keys():
		var seen2: bool = visited.get(pos, false)
		if not seen2:
			var adj: bool = false
			for dd2 in [Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0), Vector2i(0,-1)]:
				if visited.get(pos + dd2, false): adj = true; break
			if not adj: continue
		var rx: float = gx0 + (pos.x - minx)*step
		var ry: float = gy0 + (pos.y - miny)*step
		if seen2:
			var col: Color = pal.get(rooms[pos]["style"], pal["clean"])["ac"]; col.a = 0.9
			draw_rect(Rect2(rx, ry, cell, cell), col)
			var info2: Dictionary = rooms[pos]
			var mk: float = cell*0.36
			var mc = Color(0,0,0,0)
			if bool(info2.get("shop", false)): mc = Color(0.4,1.0,0.6,0.95)
			elif info2.has("boss") or bool(info2.get("descent", false)): mc = Color(1.0,0.35,0.35,0.95)
			elif bool(info2.get("easter", false)): mc = Color(1.0,0.9,0.4,0.95)
			if mc.a > 0.0:
				draw_rect(Rect2(rx+cell*0.5-mk*0.5, ry+cell*0.5-mk*0.5, mk, mk), mc)
		else:
			draw_rect(Rect2(rx, ry, cell, cell), Color(0.28,0.34,0.42,0.35))
			draw_rect(Rect2(rx, ry, cell, cell), Color(0.5,0.6,0.7,0.5), false, 1.0)
			if cell >= 11.0:
				draw_string(font, Vector2(rx+cell*0.33, ry+cell*0.74), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(cell*0.6), Color(0.62,0.72,0.82,0.75))
		if pos == room_pos:
			var pulse: float = 0.55 + 0.45 * sin(menu_t * 5.0)
			draw_rect(Rect2(rx-2.0, ry-2.0, cell+4.0, cell+4.0), Color(1,1,1,pulse), false, 2.0)
	var ly: float = H - 30.0
	draw_rect(Rect2(16.0, ly, 6.0, 6.0), Color(0.4,1.0,0.6,0.95))
	draw_string(font, Vector2(26.0, ly+6.0), T("магазин","shop"), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.7,0.85,0.8))
	draw_rect(Rect2(84.0, ly, 6.0, 6.0), Color(1.0,0.35,0.35,0.95))
	draw_string(font, Vector2(94.0, ly+6.0), T("босс","boss"), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.9,0.75,0.75))
	draw_rect(Rect2(140.0, ly, 6.0, 6.0), Color(1.0,0.9,0.4,0.95))
	draw_string(font, Vector2(150.0, ly+6.0), T("секрет","secret"), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.9,0.85,0.6))
	CutScenes.ctext(self, T("Глава ","Ch ") + str(chapter) + T("   пройдено: ","   cleared: ") + str(rooms_cleared) + "   [Tab/Esc]", W*0.5, H-12.0, 8, Color(0.6,0.75,0.85))

func _draw_world() -> void:
	var W: float = COLS * TILE
	var H: float = ROWS * TILE
	var p: Dictionary = pal.get(style, pal["clean"])
	draw_set_transform(-cam * zoom + shake_px, 0.0, Vector2(zoom, zoom))
	# cull to the visible viewport (big rooms only draw what the camera sees)
	var _vw: float = W / zoom
	var _vh: float = H / zoom
	var _cx0: int = maxi(0, int(floor(cam.x / TILE)) - 2)
	var _cy0: int = maxi(0, int(floor(cam.y / TILE)) - 2)
	var _cx1: int = mini(RW, int(ceil((cam.x + _vw) / TILE)) + 2)
	var _cy1: int = mini(RH, int(ceil((cam.y + _vh) / TILE)) + 2)
	for y in range(_cy0, _cy1):
		for x in range(_cx0, _cx1):
			if tile_at(x, y) != "#":
				_draw_floor(x, y, p)
	for y in range((_cy0 | 1), _cy1, 2):
		for x in range((_cx0 | 1), _cx1, 2):
			if tile_at(x, y) == ".":
				draw_rect(Rect2(x*TILE+7, y*TILE+7, 1, 1), Color(p["ac"].r, p["ac"].g, p["ac"].b, 0.12))
	for y in range(_cy0, _cy1):
		for x in range(_cx0, _cx1):
			var ch: String = tile_at(x, y)
			var r := Rect2(x*TILE, y*TILE, TILE, TILE)
			match ch:
				"#": _draw_wall(r, x, y, p)
				"w": _draw_breakable(r, p)
				"o": _draw_barrel(r)
				"=": _draw_table(r)
				"L": _draw_laser(r)
				"*": _draw_lamp(r)
				"$": _draw_shop(r, x, y)
				"D": _draw_door(r, doors.get(Vector2i(x,y), ""))
				"^": _draw_spikes(x, y)
				"~": _draw_water(x, y)
				"T": _draw_terminal(r)
				"V": _draw_descent(r)
				"+": _draw_health(r)
				"!": _draw_health(r)
				"W": _draw_merchant(r)
				"M": _draw_heart(r)
				"y": _draw_target(r, false)
				"Y": _draw_target(r, true)
				"g": _draw_barrier(r)
				"k":
					if not has_key: _draw_keydoor(r)
				"K":
					if not has_key: _draw_key(r)
				"1": if not collected.get("1", false): _draw_weapon(r, 1)
				"2": if not collected.get("2", false): _draw_weapon(r, 2)
				"J", "X", "H", "C":
					if not collected.get(ch, false): _draw_pickup(r, ch)
	Extras.draw_decor(self, (room_pos.x*73856093)^(room_pos.y*19349663)^(ng_plus*915))
	_draw_scars()
	_draw_parts()
	_draw_lighting()
	if shield_t > 0.0 and is_instance_valid(player):
		var _sp: float = 0.5 + 0.5 * sin(menu_t * 8.0)
		draw_arc(player.position, 11.0 + _sp * 2.0, 0.0, TAU, 28, Color(0.4, 0.85, 1.0, 0.5 + 0.3 * _sp), 1.5)
		draw_circle(player.position, 11.0, Color(0.4, 0.8, 1.0, 0.10))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var _zt: Color = zone_tint.get(zone, Color(1,1,1))
	var _zta: float = 0.05 + zone_glitch.get(zone, 0.0) * 0.06
	draw_rect(Rect2(0, 0, W, H), Color(_zt.r, _zt.g, _zt.b, _zta))
	if core_glitch_t > 0.0:
		var _gi := 1.0 if core_glitch_kind == 0 else 0.0
		for _gk in range(4):
			var _gy: float = randf() * H
			draw_rect(Rect2(0, _gy, W, 1.0 + randf() * 2.0), Color(1.0, 0.2, 0.35, 0.20))
		var _gc := Color(1.0, 0.3, 0.5, 0.10) if core_glitch_kind == 0 else Color(0.4, 0.6, 1.0, 0.10)
		draw_rect(Rect2(0, 0, W, H), _gc)
		var _gtxt := "УПРАВЛЕНИЕ ИНВЕРТИРОВАНО" if core_glitch_kind == 0 else "ГРАВИТАЦИЯ ПУЛЬ"
		CutScenes.ctext(self, _gtxt, W * 0.5, 34.0, 8, Color(1.0, 0.6, 0.7))
	_draw_core_weather()
	_draw_postfx(W, H)
	if glitch_level > 0.0:
		var vg: float = glitch_level * (0.15 if reduce_shake else 0.4)
		draw_rect(Rect2(0,0,W,6), Color(0,0,0,vg))
		draw_rect(Rect2(0,H-6,W,6), Color(0,0,0,vg))
		if glitch_level > 0.5 and not reduce_shake and int(menu_t*12.0) % 9 == 0:
			draw_rect(Rect2(0, randf()*H, W, 1), Color(1,0.2,0.3,0.25))
	if lucid_flash > 0.0:
		draw_rect(Rect2(0,0,W,H), Color(0.3,0.9,0.9, lucid_flash*0.12))
	if is_instance_valid(player) and player.hp <= 2.0 and (state == St.PLAY or state == St.VIRUS or state == St.BOSS):
		var _hb: float = 0.5 + 0.5 * sin(menu_t * 7.0)
		var _edge: float = (0.22 + 0.28 * _hb) * (1.0 if player.hp <= 1.0 else 0.55)
		var _bd: float = 10.0
		draw_rect(Rect2(0, 0, W, _bd), Color(0.9, 0.1, 0.15, _edge))
		draw_rect(Rect2(0, H - _bd, W, _bd), Color(0.9, 0.1, 0.15, _edge))
		draw_rect(Rect2(0, 0, _bd, H), Color(0.9, 0.1, 0.15, _edge))
		draw_rect(Rect2(W - _bd, 0, _bd, H), Color(0.9, 0.1, 0.15, _edge))
	_draw_vignette(W, H)
	_draw_reticle()
	_draw_minimap(p)
	_draw_chatter()
	_draw_banner()
	_draw_tutorial()
	_draw_chapter_banner()
	if state == St.DIALOG: _draw_dialog()
	if state == St.TRANSFORM:
		draw_rect(Rect2(0,0,W,H), Color(0.3,0.0,0.05, glitch_level*0.25))
		draw_string(font, Vector2(W*0.5-40, H*0.8), "...ОНО больше не Nova.", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0,0.3,0.35))
	if state == St.WIN:
		_draw_win()
	if state == St.CHOICE:
		_draw_choice()
	if state == St.BOSS_INTRO:
		_draw_boss_intro()
	if state == St.NOVA_CUT:
		_draw_nova_cut()
	if state == St.ENDING:
		_draw_ending()
	if state == St.DEATH:
		_draw_death()
	if room_fade > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.03, 0.05, clamp(room_fade, 0.0, 1.0)))
	if death_flash > 0.0:
		var da: float = clamp(death_flash / 1.6, 0.0, 1.0)
		draw_rect(Rect2(0, 0, W, H), Color(0.3, 0.0, 0.03, da * 0.5))
		if nova_found and nova != null and not nova.infected:
			CutScenes.ctext(self, "NOVA: " + death_line, W * 0.5, H * 0.42, 9, Color(0.7, 1.0, 0.95, da))
		CutScenes.ctext(self, "попытка " + str(deaths + 1), W * 0.5, H * 0.52, 7, Color(0.8, 0.85, 0.95, da))

func _draw_lighting() -> void:
	var dk: float = zone_dark.get(zone, 0.0)
	if dark_room:
		dk = max(dk, 0.9)
	if dk <= 0.0:
		return
	var lamp_b: Array = []
	for i in range(lamps.size()):
		var fl: float = 0.75 + 0.25 * sin(menu_t * (6.0 + i))
		if int(menu_t * 3.0 + i * 7) % 23 == 0:
			fl = 0.15
		lamp_b.append(fl)
	# precompute source positions once (perf: avoid per-tile allocs)
	var ppos: Vector2 = player.position if is_instance_valid(player) else Vector2(-999, -999)
	var has_nova: bool = nova_found and nova != null and not nova.infected
	var npos: Vector2 = nova.position if has_nova else Vector2(-999, -999)
	var prad2 := 42.0 * 42.0
	var nrad2 := 30.0 * 30.0
	var lrad2 := 40.0 * 40.0
	var _lvw: float = (COLS * TILE) / zoom
	var _lvh: float = (ROWS * TILE) / zoom
	var _lx0: int = maxi(0, int(floor(cam.x / TILE)) - 1)
	var _ly0: int = maxi(0, int(floor(cam.y / TILE)) - 1)
	var _lx1: int = mini(RW, int(ceil((cam.x + _lvw) / TILE)) + 1)
	var _ly1: int = mini(RH, int(ceil((cam.y + _lvh) / TILE)) + 1)
	for ty in range(_ly0, _ly1):
		for tx in range(_lx0, _lx1):
			var cx := tx * TILE + TILE * 0.5
			var cy := ty * TILE + TILE * 0.5
			var cp := Vector2(cx, cy)
			var light := 0.0
			var pd2 := cp.distance_squared_to(ppos)
			if pd2 < prad2:
				light = max(light, 1.0 - sqrt(pd2) / 42.0)
			if has_nova:
				var nd2 := cp.distance_squared_to(npos)
				if nd2 < nrad2:
					light = max(light, (1.0 - sqrt(nd2) / 30.0) * 0.8)
			for i in range(lamps.size()):
				var ld2: float = cp.distance_squared_to(lamps[i])
				if ld2 < lrad2:
					light = max(light, (1.0 - sqrt(ld2) / 40.0) * lamp_b[i])
			var dark_a: float = (1.0 - light) * dk
			if dark_a > 0.02:
				draw_rect(Rect2(tx*TILE, ty*TILE, TILE, TILE), Color(0.0, 0.0, 0.02, dark_a))

func _draw_banner() -> void:
	if _banner_a <= 0.0:
		return
	_banner_a = max(0.0, _banner_a - 0.005)
	var W: float = COLS*TILE
	draw_string(font, Vector2(8, ROWS*TILE-30), _banner_text, HORIZONTAL_ALIGNMENT_CENTER, W-16, 9, Color(1,1,1,clamp(_banner_a,0.0,1.0)))

func _draw_dialog() -> void:
	var W: float = COLS*TILE; var H: float = ROWS*TILE
	draw_rect(Rect2(0,0,W,H), Color(0.02,0.03,0.05,0.85))
	var _dl: String = dialog_lines[dialog_idx]
	var _bd: String = Portraits.strip_prefix(_dl)
	var _cn: int = clampi(int((menu_t - dlg_t0) * 34.0), 0, _bd.length())
	Portraits.dialogue(self, _dl, _bd.substr(0, _cn), (nova != null and nova.infected))
	return
	var line: String = dialog_lines[dialog_idx]
	draw_string(font, Vector2(12, H*0.42), _glitchify(line), HORIZONTAL_ALIGNMENT_LEFT, W-24, 9, Color(0.85,0.95,1.0))
	if int(menu_t*2.0)%2==0:
		draw_string(font, Vector2(W*0.5-24, H-16), "[ E - далее ]", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6,0.8,0.9))

func _show_chapter_banner(title: String, subtitle: String) -> void:
	chapter_banner = title
	chapter_banner_sub = subtitle
	chapter_banner_t = 3.4

func _draw_chapter_banner() -> void:
	if chapter_banner_t <= 0.0:
		return
	var W: float = COLS * TILE
	var H: float = ROWS * TILE
	var fa: float = clamp(chapter_banner_t / 1.0, 0.0, 1.0) * clamp((3.4 - chapter_banner_t) / 0.35, 0.0, 1.0)
	var by: float = H * 0.36
	draw_rect(Rect2(0, by, W, 28), Color(0.02, 0.03, 0.06, 0.72 * fa))
	draw_rect(Rect2(0, by, W, 1), Color(0.4, 0.9, 1.0, fa))
	draw_rect(Rect2(0, by + 27, W, 1), Color(0.4, 0.9, 1.0, fa))
	CutScenes.ctext(self, chapter_banner, W * 0.5, by + 13, 14, Color(0.85, 0.97, 1.0, fa))
	CutScenes.ctext(self, chapter_banner_sub, W * 0.5, by + 23, 7, Color(0.55, 0.8, 0.92, fa))

func _seed_key(k: int) -> void:
	if k == KEY_ESCAPE:
		seed_entry = false
		return
	if k == KEY_ENTER or k == KEY_KP_ENTER:
		has_custom_seed = seed_input.length() > 0
		seed_entry = false
		if audio: audio.sfx("select")
		return
	if k == KEY_BACKSPACE:
		if seed_input.length() > 0:
			seed_input = seed_input.substr(0, seed_input.length() - 1)
		return
	if k >= KEY_0 and k <= KEY_9 and seed_input.length() < 9:
		seed_input += str(k - KEY_0)
		has_custom_seed = true
	elif k >= KEY_KP_0 and k <= KEY_KP_9 and seed_input.length() < 9:
		seed_input += str(k - KEY_KP_0)
		has_custom_seed = true

func _fmt_time(t: float) -> String:
	var s: int = int(t)
	var m: int = s / 60
	var ss: int = s % 60
	return str(m) + ":" + ("0" if ss < 10 else "") + str(ss)

func _ability_count() -> int:
	var n: int = 0
	for k in abilities:
		if abilities[k]: n += 1
	return n

func _draw_savemark() -> void:
	if save_flash <= 0.0: return
	var W: float = COLS*TILE
	var a: float = clamp(save_flash, 0.0, 1.0)
	draw_string(font, Vector2(W-70.0, 10.0), "СОХРАНЕНО", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.6, 1.0, 0.7, a))

func _draw_death() -> void:
	var W: float = COLS * TILE
	var H: float = ROWS * TILE
	var dt: float = death_t
	# world dims to black over the first second
	var dim: float = clamp(dt / 1.0, 0.0, 1.0)
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.0, 0.02, dim * 0.9))
	# the suit shatters at the death spot: shards fly out then fade
	var dp: Vector2 = death_pos
	if dt < 1.4:
		for i in range(14):
			var a: float = TAU * i / 14.0
			var dd: float = dt * (60.0 + (i % 4) * 20.0)
			var sp := dp + Vector2(cos(a), sin(a)) * dd
			var sa: float = clamp(1.0 - dt / 1.4, 0.0, 1.0)
			draw_rect(Rect2(sp.x - 1.5, sp.y - 1.5, 3, 3), Color(0.3, 0.55, 0.9, sa))
		draw_circle(dp, 4.0 + dt * 30.0, Color(0.4, 0.7, 1.0, clamp(0.5 - dt, 0.0, 0.5)))
	# red vignette pulse
	var rp: float = 0.5 + 0.5 * sin(dt * 4.0)
	for bnd in [Rect2(0,0,W,10), Rect2(0,H-10,W,10), Rect2(0,0,10,H), Rect2(W-10,0,10,H)]:
		draw_rect(bnd, Color(0.6, 0.05, 0.1, dim * (0.3 + 0.2 * rp)))
	if dt > 0.9:
		var ta: float = clamp((dt - 0.9) / 0.6, 0.0, 1.0)
		CutScenes.ctext(self, T("ТЫ ПАЛ", "YOU DIED"), W * 0.5, H * 0.40, 20, Color(0.9, 0.2, 0.25, ta))
		if nova_found:
			CutScenes.ctext(self, "NOVA: " + death_line, W * 0.5, H * 0.52, 8, Color(0.7, 0.9, 0.95, ta))
		CutScenes.ctext(self, T("Зачищено комнат: ", "Rooms cleared: ") + str(rooms_cleared) + "    " + T("Ядра: ", "Cores: ") + str(meta_cores), W * 0.5, H * 0.62, 7, Color(0.7, 0.8, 0.9, ta))
		if int(menu_t * 2.0) % 2 == 0 and dt > 1.4:
			CutScenes.ctext(self, T("SPACE - начать заново", "SPACE - restart"), W * 0.5, H - 12.0, 8, Color(0.6, 0.75, 0.85, ta))

func _draw_nova_cut() -> void:
	var W: float = COLS * TILE
	var H: float = ROWS * TILE
	var t: float = nova_cut_t
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.03, 0.05, 0.92))
	draw_rect(Rect2(0, 0, W, 16), Color(0, 0, 0, 0.95))
	draw_rect(Rect2(0, H - 16, W, 16), Color(0, 0, 0, 0.95))
	var cx: float = W * 0.5
	var cy: float = H * 0.46
	# a dead desk silhouette
	draw_rect(Rect2(cx - 40, cy + 14, 80, 8), Color(0.10, 0.10, 0.14))
	draw_rect(Rect2(cx - 36, cy + 22, 6, 10), Color(0.08, 0.08, 0.11))
	draw_rect(Rect2(cx + 30, cy + 22, 6, 10), Color(0.08, 0.08, 0.11))
	# a tiny blue light flickers, then boots into Nova
	var boot: float = clamp((t - 1.2) / 2.2, 0.0, 1.0)
	if t < 1.4:
		var fl: float = 0.3 + 0.7 * abs(sin(t * 9.0))
		draw_circle(Vector2(cx, cy + 8), 2.0, Color(0.4, 0.9, 1.0, fl))
		draw_circle(Vector2(cx, cy + 8), 5.0, Color(0.4, 0.9, 1.0, 0.12 * fl))
	else:
		var ny: float = cy + 8.0 - boot * 10.0
		CutScenes.draw_nova(self, cx, ny, t)
		draw_circle(Vector2(cx, ny), 30.0 * boot, Color(0.3, 0.85, 1.0, 0.06))
	var cap := ""
	if t < 1.4: cap = "Среди мёртвых машин - один синий огонёк."
	elif t < 3.2: cap = "Он не заражён. Он прятался. Ждал."
	else: cap = "NOVA оживает. Ты больше не один."
	CutScenes.ctext(self, cap, W * 0.5, H - 26.0, 8, Color(0.75, 0.92, 1.0))
	if int(menu_t * 2.0) % 2 == 0:
		draw_string(font, Vector2(W - 84, H - 5), "SPACE - дальше", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.5, 0.6, 0.7))

func _draw_ending() -> void:
	var W: float = COLS * TILE
	var H: float = ROWS * TILE
	var t: float = end_t
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.02, 0.04, 1.0))
	var cx: float = W * 0.5
	var cy: float = H * 0.40
	if t < 7.0:
		# phase A (0-3.5): infected shell reverts to teal Nova
		# phase B (3.5-7): she powers down and goes dark forever
		var revert: float = clamp(t / 3.5, 0.0, 1.0)
		var down: float = clamp((t - 3.5) / 3.0, 0.0, 1.0)
		var shell := Color(0.4, 0.08, 0.1).lerp(Color(0.16, 0.66, 0.74), revert)
		var eye := Color(1.0, 0.25, 0.2).lerp(Color(0.45, 1.0, 0.95), revert)
		eye = eye.lerp(Color(0.1, 0.14, 0.16), down)
		var sink: float = down * 14.0
		var ry: float = cy + sink
		var sz: float = lerp(20.0, 15.0, revert)
		draw_circle(Vector2(cx, ry + sz * 0.9), sz, Color(0, 0, 0, 0.3))
		if revert > 0.5 and down < 1.0:
			draw_circle(Vector2(cx, ry), sz + 6.0, Color(0.3, 0.9, 1.0, 0.10 * (1.0 - down)))
		draw_rect(Rect2(cx - sz, ry - sz, sz * 2.0, sz * 1.8), shell)
		draw_rect(Rect2(cx - sz, ry - sz, sz * 2.0, 3.0), shell.lightened(0.3))
		draw_rect(Rect2(cx - sz * 0.6, ry - sz * 0.5, sz * 1.2, sz * 0.8), Color(0.04, 0.12, 0.16))
		var eb: float = (1.0 - down) * (0.6 + 0.4 * sin(t * 4.0))
		draw_circle(Vector2(cx, ry - sz * 0.1), 3.2, Color(eye.r, eye.g, eye.b, max(0.15, eb)))
		var cap := ""
		if t < 3.5: cap = "Вирус гаснет. NOVA возвращается собой."
		elif t < 5.5: cap = "NOVA: спасибо... что довёл меня до конца."
		else: cap = "Свет в её глазах гаснет. Навсегда."
		CutScenes.ctext(self, cap, cx, H - 24.0, 8, Color(0.8, 0.92, 1.0))
		if int(menu_t * 2.0) % 2 == 0:
			draw_string(font, Vector2(W - 92, H - 6), "SPACE - пропустить", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.5, 0.6, 0.7))
	else:
		_draw_end_credits(W, H, t - 7.0)

func _draw_end_credits(W: float, H: float, ct: float) -> void:
	var lines: Array = [
		"PROJECT NOVA", "",
		"разработчик", "Antropov31", "",
		("Финал: ИСТИНА" if ending == "truth" else ("Финал: ПОКОЙ" if merciful else "Финал: ЯРОСТЬ")), "",
		"Время: " + _fmt_time(game_time), "Комнат: " + str(rooms_cleared), "",
		"Спасибо, что играл.",
	]
	var base: float = H - ct * 16.0
	for i in range(lines.size()):
		var yy: float = base + i * 13.0
		if yy < -8.0 or yy > H + 8.0: continue
		var fade: float = clamp(1.0 - abs(yy - H * 0.45) / (H * 0.55), 0.15, 1.0)
		var sz: int = 14 if i == 0 else (10 if String(lines[i]) == "Antropov31" else 8)
		var col := Color(0.7, 0.95, 1.0, fade) if i == 0 else Color(0.8, 0.88, 0.96, fade * 0.9)
		CutScenes.ctext(self, String(lines[i]), W * 0.5, yy, sz, col)
	if int(menu_t * 2.0) % 2 == 0:
		draw_string(font, Vector2(W - 118, H - 5), "SPACE - в меню", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.5, 0.6, 0.7))

func _draw_credits(W: float, H: float) -> void:
	# a slow memorial scroll of the fallen; the TRUTH ending honours them all
	var names: Array = [
		"ПАМЯТИ ПОГИБШИХ", "А. Волков, инженер", "М. Соколова, охрана",
		"Д. Лебедев, техник", "Е. Мороз, смена", "К. Новак, проект NOVA",
		"и все, кого не успели спасти.",
	]
	if ending == "truth":
		names.append("")
		names.append("ты выслушал каждого.")
		names.append("NOVA свободна.")
	var base: float = H - (win_t - 2.0) * 10.0
	if win_t < 2.0:
		return
	for i in range(names.size()):
		var yy: float = base + i * 11.0
		if yy < -8.0 or yy > H + 8.0:
			continue
		var fade: float = clamp(1.0 - abs(yy - H * 0.5) / (H * 0.5), 0.2, 1.0)
		var sz: int = 9 if i == 0 else 7
		var col := Color(0.7, 0.95, 1.0, fade) if i == 0 else Color(0.75, 0.82, 0.9, fade * 0.85)
		CutScenes.ctext(self, String(names[i]), W * 0.5, yy, sz, col)

func _draw_win() -> void:
	var W: float = COLS*TILE; var H: float = ROWS*TILE
	draw_rect(Rect2(0,0,W,H), Color(0.03,0.05,0.08,0.92))
	if ending == "truth":
		draw_string(font, Vector2(W*0.5-36, H*0.3), "РИРЎРўРИНА", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7,1.0,0.85))
		draw_string(font, Vector2(16, H*0.44), "Ты выслушал всех погибших. Ядро не было злом - оно было одиноко и напугано.", HORIZONTAL_ALIGNMENT_LEFT, W-32, 8, Color(0.85,1.0,0.95))
		draw_string(font, Vector2(16, H*0.56), "Ты отпустил Nova собой. Её последний импульс стёр вирус навсегда. Она свободна.", HORIZONTAL_ALIGNMENT_LEFT, W-32, 8, Color(0.85,1.0,0.95))
	elif merciful:
		draw_string(font, Vector2(W*0.5-30, H*0.3), "ПОКОЙ", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6,1.0,0.9))
		draw_string(font, Vector2(16, H*0.44), "Ты дождался, пока в ней проснулась ОНА, и отпустил так, как она просила.", HORIZONTAL_ALIGNMENT_LEFT, W-32, 8, Color(0.8,0.95,1.0))
		draw_string(font, Vector2(16, H*0.56), "Nova ушла собой, а не вирусом. Ты запомнишь её такой.", HORIZONTAL_ALIGNMENT_LEFT, W-32, 8, Color(0.8,0.95,1.0))
	else:
		draw_string(font, Vector2(W*0.5-52, H*0.3), "ЯДРО ОТКЛЮЧЕНО", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9,0.4,0.4))
		draw_string(font, Vector2(16, H*0.44), "Вирус стёрт. Роботы замирают. Ты разбил её в ярости.", HORIZONTAL_ALIGNMENT_LEFT, W-32, 8, Color(0.85,0.85,0.9))
		draw_string(font, Vector2(16, H*0.56), "Ты спас всех. Но не услышал её последних слов. ...Прости, Nova.", HORIZONTAL_ALIGNMENT_LEFT, W-32, 8, Color(0.85,0.85,0.9))
	var st1: String = "Время: " + _fmt_time(game_time) + "    Зачищено комнат: " + str(rooms_cleared)
	var st2: String = "Улучшений: " + str(_ability_count()) + "    Валюта: " + str(currency) + "    Сид: " + str(chapter_seed) + (("    NG+" + str(ng_plus)) if ng_plus > 0 else "")
	draw_string(font, Vector2(16, H*0.70), st1, HORIZONTAL_ALIGNMENT_LEFT, W-32, 8, Color(0.7,0.85,0.95))
	draw_string(font, Vector2(16, H*0.76), st2, HORIZONTAL_ALIGNMENT_LEFT, W-32, 8, Color(0.7,0.85,0.95))
	_draw_credits(W, H)
	if int(menu_t*2.0)%2==0:
		draw_string(font, Vector2(W*0.5-72, H-16), "[ R - заново ]   [ N - Новая РИгра+ ]", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6,0.8,0.9))

func _draw_choice() -> void:
	var W: float = COLS * TILE
	var H: float = ROWS * TILE
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.03, 0.06, 0.82))
	var ap: float = clamp(choice_t / 0.22, 0.0, 1.0)
	CutScenes.ctext(self, T("ВЫБЕРИ УЛУЧШЕНИЕ", "CHOOSE AN UPGRADE"), W * 0.5, H * 0.12, 13, Color(0.75, 0.97, 1.0, ap))
	CutScenes.ctext(self, T("1 / 2 / 3 - выбор,  R - перекрутить за 3$", "1 / 2 / 3 - pick,  R - reroll 3$"), W * 0.5, H * 0.12 + 12, 7, Color(0.6, 0.75, 0.85, ap))
	var cw: float = 100.0
	var gap: float = 6.0
	var x0: float = W * 0.5 - (cw * 1.5 + gap)
	_choice_card(x0, H * 0.30, cw, choice_a, "1", Color(0.35, 0.85, 1.0), ap)
	_choice_card(x0 + cw + gap, H * 0.30, cw, choice_b, "2", Color(1.0, 0.75, 0.35), ap)
	_choice_card(x0 + (cw + gap) * 2.0, H * 0.30, cw, choice_c, "3", Color(0.6, 1.0, 0.7), ap)

func _choice_card(x: float, y: float, w: float, card: Dictionary, key: String, col: Color, ap: float) -> void:
	var h: float = 104.0
	var hov: float = 0.5 + 0.5 * sin(menu_t * 4.0 + x)
	draw_rect(Rect2(x + 2, y + 3, w, h), Color(0.0, 0.0, 0.02, 0.4 * ap))
	draw_rect(Rect2(x, y, w, h), Color(0.07, 0.10, 0.15, ap))
	draw_rect(Rect2(x, y, w, h), Color(col.r, col.g, col.b, ap * (0.6 + 0.4 * hov)), false, 1.5)
	draw_rect(Rect2(x + 2, y + 2, w - 4, h - 4), Color(col.r, col.g, col.b, ap * 0.15), false, 1.0)
	draw_rect(Rect2(x, y, w, 18), Color(col.r, col.g, col.b, ap * 0.9))
	draw_rect(Rect2(x + 4, y + 3, 12, 12), Color(0.05, 0.06, 0.1, ap))
	CutScenes.ctext(self, key, x + 10, y + 13, 10, Color(col.r, col.g, col.b, ap))
	var kind := String(card.get("kind", ""))
	var tag := T("СПОСОБНОСТЬ", "ABILITY")
	if kind == "maxhp" or kind == "heal": tag = T("ЗДОРОВЬЕ", "HEALTH")
	elif kind == "dmg": tag = T("УРОН", "DAMAGE")
	elif kind == "cash": tag = T("ВАЛЮТА", "MONEY")
	CutScenes.ctext(self, tag, x + w * 0.5 + 6, y + 13, 6, Color(0.05, 0.06, 0.1, ap))
	CutScenes.ctext(self, String(card.get("name", "")), x + w * 0.5, y + 34, 8, Color(0.92, 0.98, 1.0, ap))
	draw_rect(Rect2(x + 6, y + 40, w - 12, 1), Color(col.r, col.g, col.b, ap * 0.4))
	_wrap_text(String(card.get("desc", "")), x + 7.0, y + 52, w - 14.0, 7, Color(0.78, 0.86, 0.94, ap))

func _wrap_text(s: String, x: float, y: float, maxw: float, size: int, col: Color) -> void:
	var words: PackedStringArray = s.split(" ")
	var line: String = ""
	var yy: float = y
	for wd in words:
		var test: String = wd if line == "" else line + " " + wd
		if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > maxw and line != "":
			draw_string(font, Vector2(x, yy), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
			line = wd
			yy += size + 2
		else:
			line = test
	if line != "":
		draw_string(font, Vector2(x, yy), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _draw_chatter() -> void:
	if chat_shown == "" or nova == null or not nova_found or nova.infected:
		return
	var txt: String = _glitchify(chat_shown)
	var w: float = txt.length()*4.2 + 8.0
	var _np: Vector2 = (nova.position - cam) * zoom + shake_px
	var bx: float = clamp(_np.x - w*0.5, 2.0, COLS*TILE - w - 2.0)
	var by: float = clamp(_np.y - 22.0, 2.0, ROWS*TILE - 16.0)
	var frame := Color(0.3,0.9,0.9,0.7)
	if lucid_flash > 0.0: frame = Color(0.5,1.0,0.95,0.9)
	draw_rect(Rect2(bx, by, w, 11), Color(0.03,0.06,0.09,0.92))
	draw_rect(Rect2(bx, by, w, 1), frame)
	draw_rect(Rect2(bx, by+10, w, 1), Color(0.1,0.3,0.35,0.7))
	var col := Color(0.7,1.0,0.95)
	if glitch_level > 0.5: col = Color(0.9,0.8,0.85)
	draw_string(font, Vector2(bx+4, by+8), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, col)

func _draw_minimap(p: Dictionary) -> void:
	var cell := 3.2; var gap := 1.4
	var minx := 999; var maxx := -999; var miny := 999; var maxy := -999
	for pos in rooms.keys():
		minx = mini(minx, pos.x); maxx = maxi(maxx, pos.x)
		miny = mini(miny, pos.y); maxy = maxi(maxy, pos.y)
	var step: float = cell + gap
	var ox: float = COLS*TILE - float(maxx - minx + 1)*step - 3.0
	var oy: float = 4.0
	for pos in rooms.keys():
		if not visited.get(pos, false): continue
		var bx: float = ox + (pos.x - minx)*step + cell*0.5
		var by: float = oy + (pos.y - miny)*step + cell*0.5
		for dd in [Vector2i(1,0), Vector2i(0,1)]:
			var nb: Vector2i = pos + dd
			if rooms.has(nb) and visited.get(nb, false):
				var nx: float = ox + (nb.x - minx)*step + cell*0.5
				var ny: float = oy + (nb.y - miny)*step + cell*0.5
				draw_line(Vector2(bx,by), Vector2(nx,ny), Color(0.5,0.6,0.7,0.5), 0.8)
	for pos in rooms.keys():
		var rx: float = ox + (pos.x - minx)*step
		var ry: float = oy + (pos.y - miny)*step
		var col := Color(0.2,0.24,0.3,0.5)
		if visited.get(pos, false):
			col = pal.get(rooms[pos]["style"], pal["clean"])["ac"]; col.a = 0.85
		draw_rect(Rect2(rx, ry, cell, cell), col)
		if pos == room_pos:
			draw_rect(Rect2(rx-0.6, ry-0.6, cell+1.2, cell+1.2), Color(1,1,1,0.95), false, 1.0)

func _joy_button(b: int) -> void:
	if state == St.MENU:
		if b == JOY_BUTTON_START or b == JOY_BUTTON_A: _menu_start()
		return
	if state == St.DIALOG or state == St.BOSS_INTRO:
		if b == JOY_BUTTON_A or b == JOY_BUTTON_START:
			if state == St.DIALOG: _advance_dialog()
			else: _end_boss_intro()
		return
	if state == St.PLAY or state == St.VIRUS or state == St.BOSS:
		if b == JOY_BUTTON_X: interact()
		elif b == JOY_BUTTON_Y: player.cycle_weapon()
		elif b == JOY_BUTTON_B: nova_pulse()
		elif b == JOY_BUTTON_RIGHT_SHOULDER: use_active_item()
		elif b == JOY_BUTTON_START: paused = not paused

func _draw_tutorial() -> void:
	if chapter != 1 or room_pos != Vector2i(0, 0) or state != St.PLAY:
		return
	var W: float = COLS * TILE
	var H: float = ROWS * TILE
	var hints: Array = ["WASD - идти", "мышь - прицел", "ЛКМ / J - огонь", "E - действие", "Q - смена оружия"]
	hints.append(T("TAB/M - карта", "TAB/M - map"))
	var idx: int = int(menu_t / 2.2) % hints.size()
	var a: float = clamp(1.0 - abs(fmod(menu_t, 2.2) - 1.1) / 1.1, 0.35, 1.0)
	CutScenes.ctext(self, String(hints[idx]), W * 0.5, H * 0.5 - 20.0, 9, Color(0.8, 0.95, 1.0, a))

func _draw_reticle() -> void:
	if not is_instance_valid(player):
		return
	if not (state == St.PLAY or state == St.VIRUS or state == St.BOSS):
		return
	var mp: Vector2 = get_local_mouse_position()
	var col := Color(0.6, 1.0, 0.95, 0.85)
	if player.weapon == 1: col = Color(1.0, 0.85, 0.4, 0.85)
	elif player.weapon == 2: col = Color(0.75, 0.55, 1.0, 0.85)
	var sp: float = 1.5 + 0.5 * sin(menu_t * 6.0)
	for a in range(4):
		var ang: float = TAU * a / 4.0
		var d := Vector2(cos(ang), sin(ang))
		draw_line(mp + d * (2.0 + sp), mp + d * (5.0 + sp), col, 1.0)
	draw_circle(mp, 0.8, col)

func _draw_wall(r: Rect2, x: int, y: int, p: Dictionary) -> void:
	var bx: float = r.position.x
	var by: float = r.position.y
	var open_below: bool = tile_at(x, y + 1) != "#"
	var edge: bool = (x==0 or y==0 or x==RW-1 or y==RH-1)
	var base: Color = p["wall"]
	if not edge: base = base.lightened(0.06)
	# recessed side faces (darker) to fake extrusion
	draw_rect(r, base.darkened(0.18))
	# raised top cap: a lighter block inset from bottom, so the wall looks 3D
	var cap_h: float = TILE - 3.0 if open_below else TILE
	draw_rect(Rect2(bx + 1, by, TILE - 2, cap_h), base)
	draw_rect(Rect2(bx + 1, by, TILE - 2, 3), base.lightened(0.34))
	draw_rect(Rect2(bx + 1, by, 2, cap_h), base.lightened(0.14))
	draw_rect(Rect2(bx + TILE - 3, by, 2, cap_h), base.darkened(0.28))
	if open_below:
		draw_rect(Rect2(bx + 1, by + cap_h - 1, TILE - 2, 2), base.darkened(0.5))
	draw_rect(Rect2(r.position.x+2, r.position.y+4, 1, 1), base.lightened(0.35))
	draw_rect(Rect2(r.position.x+TILE-4, r.position.y+TILE-5, 1, 1), base.darkened(0.3))
	if not edge:
		var ac: Color = p["ac"]
		_wall_detail(r.position.x, r.position.y, x, y, p, base, edge)

func _draw_breakable(r: Rect2, p: Dictionary) -> void:
	# a bolted blast panel plugging the passage - clearly a barrier, needs a grenade
	var x := int(r.position.x / TILE)
	var y := int(r.position.y / TILE)
	_draw_wall(r, x, y, p)
	var b := r.position
	var warn := Color(0.85, 0.7, 0.2)
	# hazard chevrons + rivets so the player learns "this is destructible"
	draw_rect(Rect2(b.x + 2, b.y + 6, TILE - 4, 4), Color(0.10, 0.10, 0.12))
	for i in range(3):
		draw_rect(Rect2(b.x + 2 + i * 4, b.y + 6, 2, 4), warn)
	draw_circle(Vector2(b.x + 3, b.y + 3), 1.0, Color(0.6, 0.6, 0.66))
	draw_circle(Vector2(b.x + TILE - 3, b.y + 3), 1.0, Color(0.6, 0.6, 0.66))
	draw_circle(Vector2(b.x + 3, b.y + TILE - 3), 1.0, Color(0.6, 0.6, 0.66))
	draw_circle(Vector2(b.x + TILE - 3, b.y + TILE - 3), 1.0, Color(0.6, 0.6, 0.66))

func _draw_gloss_reflection() -> void:
	if style != "clean" and style != "glass" and style != "server":
		return
	if not is_instance_valid(player):
		return
	var pp: Vector2 = player.position
	var wob: float = sin(menu_t * 2.5) * 0.8
	draw_rect(Rect2(pp.x - 4 + wob, pp.y + 6, 8, 9), Color(0.5, 0.7, 1.0, 0.06))
	draw_circle(Vector2(pp.x + wob, pp.y + 14), 4.0, Color(0.5, 0.75, 1.0, 0.05))
	if nova_found and nova != null and not nova.infected:
		var np: Vector2 = nova.position
		draw_circle(Vector2(np.x, np.y + 12), 3.0, Color(0.4, 0.9, 1.0, 0.06))

func _draw_core_weather() -> void:
	if zone != "core":
		return
	var W: float = COLS * TILE
	var H: float = ROWS * TILE
	for i in range(16):
		var ax: float = fmod(i * 53.0 + menu_t * (6.0 + float(i % 4) * 2.0), W)
		var ay: float = fmod(i * 37.0 + menu_t * 10.0, H)
		var aa: float = 0.10 + 0.10 * sin(menu_t * 2.0 + i)
		draw_rect(Rect2(ax, ay, 1.0, 2.0), Color(0.8, 0.2, 0.25, aa))
	if int(menu_t * 6.0) % 37 == 0:
		var lx: float = randf() * W
		draw_line(Vector2(lx, 0), Vector2(lx + randf_range(-8, 8), H), Color(1.0, 0.3, 0.4, 0.18), 1.0)

func _draw_water(x: int, y: int) -> void:
	var bx: float = x * TILE
	var by: float = y * TILE
	var p: Dictionary = pal.get(style, pal["clean"])
	var ac: Color = p["ac"]
	# dark reflective pool
	draw_rect(Rect2(bx, by, TILE, TILE), Color(0.04, 0.09, 0.14, 0.82))
	# moving surface highlights
	for i in range(3):
		var wy: float = by + 3.0 + i * 5.0
		var sh: float = sin(menu_t * 2.0 + x * 0.6 + i * 1.3) * 2.0
		draw_line(Vector2(bx + 2 + sh, wy), Vector2(bx + TILE - 2 + sh, wy), Color(ac.r, ac.g, ac.b, 0.14), 1.0)
	draw_rect(Rect2(bx, by, TILE, 1), Color(ac.r, ac.g, ac.b, 0.10))

func _draw_water_reflections() -> void:
	# mirror the player (and Nova) as a dim, wavering reflection on nearby water
	if not is_instance_valid(player):
		return
	var ptx := int(floor(player.position.x / TILE))
	var pty := int(floor(player.position.y / TILE))
	for ddy in range(0, 3):
		if tile_at(ptx, pty + ddy) == "~":
			var ry: float = (pty + ddy) * TILE + TILE
			var wob: float = sin(menu_t * 3.0) * 1.5
			var mx: float = player.position.x + wob
			var refl_y: float = ry + (ry - player.position.y) * 0.35
			draw_circle(Vector2(mx, refl_y), 5.0, Color(0.4, 0.7, 1.0, 0.16))
			draw_rect(Rect2(mx - 3, refl_y - 4, 6, 8), Color(0.3, 0.55, 0.85, 0.12))
			break

func _draw_lamp(r: Rect2) -> void:
	var c: Vector2 = r.position + Vector2(TILE*0.5, 2.0)
	var fl: float = 0.7 + 0.3*sin(menu_t*7.0 + r.position.x)
	if int(menu_t*3.0 + r.position.x) % 23 == 0: fl = 0.2
	draw_rect(Rect2(c.x-3, r.position.y, 6, 2), Color(0.3,0.3,0.34))
	draw_rect(Rect2(c.x-2, r.position.y+2, 4, 1), Color(1.0,0.95,0.7, fl))
	draw_circle(Vector2(c.x, r.position.y+3), 5.0*fl, Color(1.0,0.95,0.7, 0.18*fl))

func _draw_shop(r: Rect2, x: int, y: int) -> void:
	var b := r.position
	var off := _shop_offer(x, y)
	var col := Color(0.4,0.95,0.6)
	if off["id"] == "maxhp": col = Color(1.0,0.4,0.5)
	elif off["id"] == "ability": col = Color(0.6,0.7,1.0)
	elif off["id"] == "pulse": col = Color(0.4,0.85,1.0)
	# pedestal base
	draw_rect(Rect2(b.x+3, b.y+11, 10, 4), Color(0.16,0.2,0.24))
	draw_rect(Rect2(b.x+3, b.y+11, 10, 1), Color(0.3,0.36,0.42))
	draw_rect(Rect2(b.x+5, b.y+9, 6, 2), Color(0.12,0.16,0.2))
	# hovering holo-item with glow ring
	var bob: float = sin(menu_t*4.0)*1.4
	var ic := Vector2(b.x+TILE*0.5, b.y+4+bob)
	var gp: float = 0.5 + 0.5 * sin(menu_t * 5.0)
	draw_arc(ic, 6.0 + gp * 1.5, 0.0, TAU, 20, Color(col.r,col.g,col.b, 0.4 + 0.3*gp), 1.0)
	draw_circle(ic, 5.0, Color(col.r,col.g,col.b,0.16))
	draw_rect(Rect2(ic.x-3, ic.y-3, 6, 6), col)
	draw_rect(Rect2(ic.x-1.5, ic.y-1.5, 3, 3), Color(1,1,1,0.9))
	# holo beam from pedestal to item
	draw_line(Vector2(ic.x, b.y+9), ic, Color(col.r,col.g,col.b,0.15), 3.0)
	# small price tag always
	draw_string(font, Vector2(b.x+3, b.y+TILE-1), "$" + str(off["cost"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.9,1.0,0.8))
	# proximity tooltip: only when the player stands next to this pedestal
	if is_instance_valid(player):
		var cc := Vector2(b.x+TILE*0.5, b.y+TILE*0.5)
		if player.position.distance_to(cc) < TILE * 1.6:
			_shop_tooltip(b, off)

func _shop_tooltip(b: Vector2, off: Dictionary) -> void:
	var W: float = COLS * TILE
	var nm: String = str(off["name"])
	var ds: String = _offer_desc(off)
	var pw: float = max(nm.length(), ds.length()) * 4.4 + 14.0
	pw = clamp(pw, 60.0, 150.0)
	var ph: float = 34.0
	var px: float = clamp(b.x + TILE*0.5 - pw*0.5, 2.0, W - pw - 2.0)
	var py: float = b.y - ph - 3.0
	if py < 2.0: py = b.y + TILE + 3.0
	var afford: bool = currency >= int(off["cost"])
	var acc := Color(0.5,1.0,0.7) if afford else Color(1.0,0.5,0.5)
	draw_rect(Rect2(px, py, pw, ph), Color(0.04,0.06,0.10,0.96))
	draw_rect(Rect2(px, py, pw, ph), acc, false, 1.0)
	draw_rect(Rect2(px, py, pw, 2.0), acc)
	draw_string(font, Vector2(px+5, py+11), nm, HORIZONTAL_ALIGNMENT_LEFT, pw-10, 8, Color(0.92,0.98,1.0))
	draw_string(font, Vector2(px+5, py+21), ds, HORIZONTAL_ALIGNMENT_LEFT, pw-10, 6, Color(0.7,0.82,0.9))
	draw_string(font, Vector2(px+5, py+31), T("Цена: ", "Price: ") + "$" + str(off["cost"]) + "   " + T("E купить", "E buy"), HORIZONTAL_ALIGNMENT_LEFT, pw-10, 7, acc)

func _draw_table(r: Rect2) -> void:
	var b := r.position
	draw_rect(Rect2(b.x, b.y+4, TILE, 6), Color(0.3,0.33,0.4))
	draw_rect(Rect2(b.x, b.y+4, TILE, 2), Color(0.45,0.5,0.6))
	draw_rect(Rect2(b.x+2, b.y+10, 2, 4), Color(0.2,0.22,0.28))
	draw_rect(Rect2(b.x+TILE-4, b.y+10, 2, 4), Color(0.2,0.22,0.28))

func _draw_barrel(r: Rect2) -> void:
	var b := r.position
	draw_rect(Rect2(b.x+3, b.y+2, 10, 13), Color(0.55,0.35,0.15))
	draw_rect(Rect2(b.x+3, b.y+2, 10, 2), Color(0.7,0.5,0.2))
	draw_rect(Rect2(b.x+3, b.y+6, 10, 1), Color(0.3,0.18,0.08))
	draw_rect(Rect2(b.x+3, b.y+10, 10, 1), Color(0.3,0.18,0.08))
	draw_rect(Rect2(b.x+6, b.y+4, 4, 3), Color(1.0,0.85,0.2))
	var pulse: float = 0.5+0.5*sin(menu_t*5.0)
	draw_rect(Rect2(b.x+7, b.y+8, 2, 2), Color(1.0,0.4,0.2, 0.4+0.5*pulse))

func _draw_laser(r: Rect2) -> void:
	var b := r.position
	draw_rect(Rect2(b.x+5, b.y, 6, 2), Color(0.4,0.42,0.48))
	draw_rect(Rect2(b.x+5, b.y+TILE-2, 6, 2), Color(0.4,0.42,0.48))
	if laser_on:
		draw_rect(Rect2(b.x+6, b.y, 4, TILE), Color(1.0,0.2,0.3,0.35))
		draw_rect(Rect2(b.x+7, b.y, 2, TILE), Color(1.0,0.5,0.5,0.9))
	else:
		draw_rect(Rect2(b.x+7, b.y+6, 2, 4), Color(0.5,0.2,0.2,0.5))

func _draw_door(r: Rect2, side: String) -> void:
	var locked: bool = _door_locked(side)
	if locked:
		draw_rect(r, Color(0.12,0.10,0.12))
		var pulse: float = 0.5+0.5*sin(menu_t*6.0)
		draw_rect(Rect2(r.position.x+2, r.position.y, TILE-4, TILE), Color(0.8,0.2,0.25, 0.4+0.4*pulse))
		for i in range(3):
			draw_rect(Rect2(r.position.x+2, r.position.y+3+i*5, TILE-4, 1), Color(0.8,0.2,0.25))
	else:
		draw_rect(r, (pal.get(style, pal["clean"])["f0"] as Color).darkened(0.2))
		draw_rect(Rect2(r.position.x, r.position.y, TILE, 1), Color(0.3,0.8,0.7,0.4))

func _draw_target(r: Rect2, hit: bool) -> void:
	var c: Vector2 = r.position + Vector2(TILE*0.5, TILE*0.5)
	if hit:
		draw_circle(c, 5.0, Color(0.2,0.25,0.28))
		draw_circle(c, 2.0, Color(0.4,0.45,0.5))
		draw_line(c+Vector2(-3,-3), c+Vector2(3,3), Color(0.5,0.55,0.6), 1.0)
		return
	var pulse: float = 0.5+0.5*sin(menu_t*4.0)
	draw_circle(c, 6.0, Color(0.9,0.9,0.95))
	draw_circle(c, 4.0, Color(0.9,0.3,0.3))
	draw_circle(c, 2.0, Color(0.95,0.95,1.0))
	draw_circle(c, 1.0, Color(0.9,0.2,0.2))
	draw_circle(c, 7.0+pulse, Color(1.0,0.4,0.4,0.15))

func _draw_barrier(r: Rect2) -> void:
	var b := r.position
	var pulse: float = 0.5+0.5*sin(menu_t*4.0 + b.y*0.2)
	draw_rect(Rect2(b.x+2, b.y, TILE-4, TILE), Color(0.2,0.5,0.9, 0.25+0.25*pulse))
	draw_rect(Rect2(b.x+6, b.y, 4, TILE), Color(0.5,0.8,1.0, 0.5+0.3*pulse))

func _draw_keydoor(r: Rect2) -> void:
	var b := r.position
	draw_rect(r, Color(0.12,0.10,0.14))
	var pulse: float = 0.5+0.5*sin(menu_t*5.0)
	draw_rect(Rect2(b.x+2, b.y, TILE-4, TILE), Color(0.9,0.75,0.2, 0.4+0.3*pulse))
	for i in range(3):
		draw_rect(Rect2(b.x+2, b.y+3+i*5, TILE-4, 1), Color(0.9,0.75,0.2))
	draw_circle(Vector2(b.x+TILE*0.5, b.y+TILE*0.5), 2.0, Color(0.15,0.12,0.05))

func _draw_key(r: Rect2) -> void:
	var c: Vector2 = r.position + Vector2(TILE*0.5, TILE*0.5)
	c.y += sin(menu_t*4.0)*1.5
	var col := Color(1.0,0.85,0.3)
	draw_circle(c, 7.0+sin(menu_t*5.0)*1.5, Color(col.r,col.g,col.b,0.18))
	draw_circle(c+Vector2(-3,0), 2.5, col)
	draw_circle(c+Vector2(-3,0), 1.0, Color(0.15,0.12,0.05))
	draw_rect(Rect2(c.x-1, c.y-1, 6, 2), col)
	draw_rect(Rect2(c.x+3, c.y+1, 1, 2), col)
	draw_rect(Rect2(c.x+1, c.y+1, 1, 2), col)

func _draw_spikes(x: int, y: int) -> void:
	var b := Vector2(x*TILE, y*TILE)
	draw_rect(Rect2(b.x, b.y, TILE, TILE), Color(0.12,0.10,0.12))
	var hot: float = 0.5+0.5*sin(menu_t*4.0+x)
	for i in range(4):
		draw_colored_polygon(PackedVector2Array([
			Vector2(b.x+i*4, b.y+TILE),
			Vector2(b.x+i*4+2, b.y+3),
			Vector2(b.x+i*4+4, b.y+TILE)]), Color(0.7,0.75,0.82))
	draw_rect(Rect2(b.x, b.y+TILE-2, TILE, 2), Color(0.9,0.3+hot*0.3,0.2,0.5))

func _draw_terminal(r: Rect2) -> void:
	var b := r.position
	draw_rect(Rect2(b.x+2, b.y+3, 12, 9), Color(0.08,0.35,0.45))
	var flick: float = 0.5+0.5*sin(menu_t*8.0)
	draw_rect(Rect2(b.x+3, b.y+4, 10, 7), Color(0.2,0.7+flick*0.3,0.9))
	for ln in range(3):
		draw_rect(Rect2(b.x+4, b.y+5+ln*2, 6+ln, 1), Color(0.05,0.2,0.3))
	draw_rect(Rect2(b.x+6, b.y+12, 4, 3), Color(0.12,0.15,0.2))

func _draw_merchant(r: Rect2) -> void:
	var b := r.position
	var bob: float = sin(menu_t * 3.0) * 1.0
	var cx: float = b.x + TILE * 0.5
	var cy: float = b.y + TILE * 0.5 + bob
	draw_circle(Vector2(cx, cy + 6.0), 6.0, Color(0, 0, 0, 0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(cx-6, cy+6), Vector2(cx-4, cy-6), Vector2(cx+4, cy-6), Vector2(cx+6, cy+6)]), Color(0.20, 0.24, 0.34))
	draw_colored_polygon(PackedVector2Array([Vector2(cx-4, cy-5), Vector2(cx, cy-9), Vector2(cx+4, cy-5)]), Color(0.14, 0.17, 0.26))
	var gl: float = 0.6 + 0.4 * sin(menu_t * 5.0)
	draw_circle(Vector2(cx-1.6, cy-4.0), 0.9, Color(0.5, 1.0, 0.7, gl))
	draw_circle(Vector2(cx+1.6, cy-4.0), 0.9, Color(0.5, 1.0, 0.7, gl))
	draw_circle(Vector2(cx, cy - 12.0 + bob), 2.0, Color(1.0, 0.85, 0.3, 0.9))
	draw_string(font, Vector2(b.x - 4.0, b.y - 4.0), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.9, 1.0, 0.85, gl))

func _draw_health(r: Rect2) -> void:
	var c: Vector2 = r.position + Vector2(TILE*0.5, TILE*0.5)
	c.y += sin(menu_t*4.0)*1.2
	var pulse: float = 3.0+sin(menu_t*6.0)*1.5
	draw_circle(c, pulse+3.0, Color(0.4,1.0,0.5,0.2))
	draw_rect(Rect2(c.x-4, c.y-4, 8, 8), Color(0.1,0.5,0.2))
	draw_rect(Rect2(c.x-3, c.y-3, 6, 6), Color(0.3,0.9,0.4))
	draw_rect(Rect2(c.x-2, c.y-0.5, 4, 1), Color(1,1,1))
	draw_rect(Rect2(c.x-0.5, c.y-2, 1, 4), Color(1,1,1))

func _draw_heart(r: Rect2) -> void:
	var c: Vector2 = r.position + Vector2(TILE*0.5, TILE*0.5)
	c.y += sin(menu_t*4.0)*1.5
	var pulse: float = sin(menu_t*6.0)
	draw_circle(c, 8.0+pulse*2.0, Color(1.0,0.3,0.4,0.18))
	var col := Color(1.0,0.35,0.45)
	draw_rect(Rect2(c.x-4, c.y-3, 3, 3), col)
	draw_rect(Rect2(c.x+1, c.y-3, 3, 3), col)
	draw_rect(Rect2(c.x-4, c.y-1, 8, 3), col)
	draw_rect(Rect2(c.x-3, c.y+2, 6, 1), col)
	draw_rect(Rect2(c.x-1, c.y+3, 2, 1), col)
	draw_rect(Rect2(c.x-3, c.y-2, 1, 1), Color(1,0.8,0.85))

func _draw_weapon(r: Rect2, kind: int) -> void:
	var c: Vector2 = r.position + Vector2(TILE*0.5, TILE*0.5)
	c.y += sin(menu_t*4.0)*1.5
	var col := Color(1.0,0.8,0.4) if kind == 1 else Color(0.7,0.5,1.0)
	draw_circle(c, 7.0+sin(menu_t*5.0)*1.5, Color(col.r,col.g,col.b,0.18))
	draw_rect(Rect2(c.x-5, c.y-2, 8, 3), col)
	draw_rect(Rect2(c.x-5, c.y+1, 3, 3), col.darkened(0.2))
	draw_rect(Rect2(c.x+3, c.y-1, 2, 1), Color(1,1,1))

func _draw_pickup(r: Rect2, ch: String) -> void:
	# each ability keeps a consistent colour language with its HUD icon
	var col: Color = Color(0.5,0.95,1.0)   # J spread -> blaster cyan (matches ЗАЛП)
	if ch == "X": col = Color(0.5,0.85,1.0)  # dash -> ice blue (matches РЫВ)
	elif ch == "H": col = Color(0.6,1.0,0.7)  # hack -> green (matches ВЗЛ)
	elif ch == "C": col = Color(1.0,0.55,0.55) # blast -> red (matches РЈРЎРИЛ)
	var c: Vector2 = r.position + Vector2(TILE*0.5, TILE*0.5)
	c.y += sin(menu_t*4.0)*1.5
	var pulse: float = sin(menu_t*5.0)
	# double halo + rotating spark ring, colour-keyed to the ability
	draw_circle(c, 9.0+pulse*2.0, Color(col.r,col.g,col.b,0.10))
	for _si in range(4):
		var _a: float = menu_t * 1.6 + TAU * _si / 4.0
		var _rr: float = 8.0 + pulse * 1.5
		draw_circle(c + Vector2(cos(_a), sin(_a)) * _rr, 0.9, Color(col.r, col.g, col.b, 0.5))
	draw_circle(c, 7.0+pulse*1.5, Color(col.r,col.g,col.b,0.18))
	draw_colored_polygon(PackedVector2Array([
		c+Vector2(0,-5), c+Vector2(5,0), c+Vector2(0,5), c+Vector2(-5,0)]), col)
	draw_colored_polygon(PackedVector2Array([
		c+Vector2(0,-3), c+Vector2(3,0), c+Vector2(0,3), c+Vector2(-3,0)]), Color(1,1,1,0.9))

func _thash(x: int, y: int) -> float:
	var h: int = abs((x*73856093) ^ (y*19349663))
	return float(h % 1000) / 1000.0

func _draw_floor(x: int, y: int, p: Dictionary) -> void:
	var bx: float = x * TILE
	var by: float = y * TILE
	var fc: Color = p["f0"] if (x + y) % 2 == 0 else p["f1"]
	draw_rect(Rect2(bx, by, TILE, TILE), fc)
	# base tile: subtle inner gradient + bevel so floors read as 3D plates
	draw_rect(Rect2(bx, by + TILE - 3, TILE, 3), fc.darkened(0.16))
	draw_rect(Rect2(bx, by, TILE, 1), fc.lightened(0.10))
	var ac: Color = p["ac"]
	var h: float = _thash(x, y)
	# a faint large-scale grime blotch spanning tiles (uses world coords)
	var g2: float = _thash(x >> 1, y >> 1)
	if g2 < 0.22:
		draw_circle(Vector2(bx + TILE * 0.5, by + TILE * 0.5), 6.0 + g2 * 10.0, Color(0.0, 0.0, 0.0, 0.06))
	match style:
		"clean", "glass":
			draw_rect(Rect2(bx, by, TILE, 1), fc.darkened(0.22))
			draw_rect(Rect2(bx, by, 1, TILE), fc.darkened(0.22))
			# glossy tile highlight + occasional seam sparkle
			draw_rect(Rect2(bx+1, by+1, TILE-2, 1), Color(1,1,1,0.04))
			if h < 0.14:
				draw_rect(Rect2(bx+2, by+2, 3, 3), Color(1,1,1,0.06))
			if h > 0.9:
				draw_rect(Rect2(bx+TILE-4, by+TILE-4, 1, 1), Color(ac.r, ac.g, ac.b, 0.25))
		"office":
			# carpet fleck + plank seams
			if h < 0.55:
				draw_rect(Rect2(bx + int(h*12.0), by + int(fmod(h*31.0,12.0)), 1, 1), fc.lightened(0.18))
			if h < 0.3:
				draw_rect(Rect2(bx + int(h*20.0)%TILE, by+3, 1, 1), fc.lightened(0.12))
			if ((x*3 + y) % 4) == 0:
				draw_rect(Rect2(bx, by, 1, TILE), fc.darkened(0.18))
			draw_rect(Rect2(bx, by+TILE-1, TILE, 1), fc.darkened(0.12))
		"archive":
			draw_rect(Rect2(bx, by, TILE, 1), fc.darkened(0.3))
			if h < 0.28:
				draw_line(Vector2(bx+2+h*8.0, by+3), Vector2(bx+6+h*6.0, by+12), Color(0,0,0,0.22), 1.0)
		"shop":
			draw_rect(Rect2(bx, by, TILE, 1), fc.darkened(0.2))
			draw_rect(Rect2(bx, by, 1, TILE), fc.darkened(0.2))
			if h < 0.12:
				draw_rect(Rect2(bx+6, by+6, 2, 2), Color(ac.r, ac.g, ac.b, 0.15))
		"server":
			var gy: int = 0
			while gy < TILE:
				draw_rect(Rect2(bx, by+gy, TILE, 1), fc.darkened(0.32))
				gy += 3
			if h < 0.2:
				draw_rect(Rect2(bx+3, by+3, 2, 2), Color(ac.r, ac.g, ac.b, 0.2))
		"pipes":
			draw_rect(Rect2(bx, by, TILE, 1), fc.lightened(0.12))
			draw_rect(Rect2(bx, by+TILE-1, TILE, 1), fc.darkened(0.3))
			draw_circle(Vector2(bx+2, by+2), 0.9, fc.darkened(0.4))
			draw_circle(Vector2(bx+TILE-2, by+2), 0.9, fc.darkened(0.4))
			if h < 0.1:
				draw_rect(Rect2(bx+4, by+8, 6, 3), Color(0.2,0.5,0.6,0.12))
		"approach":
			if h < 0.3:
				draw_line(Vector2(bx+h*10.0, by+2), Vector2(bx+3+h*8.0, by+13), Color(0,0,0,0.28), 1.0)
			if (x+y) % 7 == 0:
				draw_rect(Rect2(bx, by+6, TILE, 3), Color(0.85,0.6,0.1,0.1))
			var gp: float = 0.5+0.5*sin(menu_t*3.0 + x*0.5)
			draw_rect(Rect2(bx, by, TILE, TILE), Color(ac.r, ac.g, ac.b, 0.03*gp))
		"core":
			var gp2: float = 0.4+0.6*sin(menu_t*2.5 + h*6.28)
			if h < 0.35:
				draw_line(Vector2(bx, by+h*TILE), Vector2(bx+TILE, by+fmod(h*19.0,1.0)*TILE), Color(1.0,0.2,0.3, 0.08*gp2), 1.0)
			draw_circle(Vector2(bx+TILE*0.5, by+TILE*0.5), 1.0, Color(1.0,0.25,0.35, 0.1*gp2))

func _wall_detail(bx: float, by: float, x: int, y: int, p: Dictionary, base: Color, edge: bool) -> void:
	var ac: Color = p["ac"]
	match style:
		"server":
			for i in range(3):
				draw_rect(Rect2(bx+3, by+3+i*4, TILE-6, 2), base.darkened(0.4))
				var bl: float = 0.3+0.7*(0.5+0.5*sin(menu_t*4.0 + i + x))
				draw_rect(Rect2(bx+TILE-4, by+3+i*4, 1, 1), Color(ac.r, ac.g, ac.b, bl))
		"pipes":
			draw_rect(Rect2(bx+TILE*0.5-2, by, 4, TILE), base.lightened(0.12))
			draw_rect(Rect2(bx+TILE*0.5-2, by, 1, TILE), base.lightened(0.3))
			draw_circle(Vector2(bx+4, by+4), 1.0, base.darkened(0.4))
			draw_circle(Vector2(bx+TILE-4, by+TILE-4), 1.0, base.darkened(0.4))
		"archive":
			draw_rect(Rect2(bx+2, by+5, TILE-4, 1), base.darkened(0.3))
			draw_rect(Rect2(bx+2, by+10, TILE-4, 1), base.darkened(0.3))
		"core", "approach":
			var gp: float = 0.4+0.6*sin(menu_t*3.0 + x*0.7 + y)
			draw_line(Vector2(bx+3, by+2), Vector2(bx+TILE-4, by+TILE-3), Color(ac.r, ac.g, ac.b, 0.28*gp), 1.0)
		_:
			if not edge:
				draw_rect(Rect2(bx+5, by+5, 6, 6), Color(ac.r, ac.g, ac.b, 0.22))
	if not edge:
		draw_rect(Rect2(bx+1, by+TILE*0.5, TILE-2, 1), base.darkened(0.2))


func _enemy_color(kind: String) -> Color:
	match kind:
		"fly": return Color(0.7, 0.4, 0.95)
		"turret": return Color(1.0, 0.6, 0.2)
		"hunter": return Color(0.4, 0.8, 1.0)
		"elite": return Color(0.9, 0.35, 0.62)
		"boss": return Color(1.0, 0.4, 0.4)
	return Color(0.95, 0.4, 0.32)

func _spawn_death_burst(pos: Vector2, col: Color) -> void:
	# metal shards
	for i in range(9):
		var a: float = randf() * TAU
		var sp: float = 40.0 + randf() * 110.0
		parts.append({"x": pos.x, "y": pos.y, "vx": cos(a) * sp, "vy": sin(a) * sp, "t": 0.0, "life": 0.35 + randf() * 0.3, "col": col, "r": 1.5 + randf() * 1.8})
	# a couple of smoke puffs
	for i in range(3):
		var a2: float = randf() * TAU
		parts.append({"x": pos.x, "y": pos.y, "vx": cos(a2) * 20.0, "vy": sin(a2) * 20.0 - 12.0, "t": 0.0, "life": 0.5, "col": Color(0.5, 0.5, 0.55), "r": 2.4})
	# a bright flash ring
	parts.append({"x": pos.x, "y": pos.y, "vx": 0.0, "vy": 0.0, "t": 0.0, "life": 0.22, "col": Color(1.0, 0.9, 0.7), "r": 4.0, "ring": true})
	shake = max(shake, 0.18)
	hitstop = max(hitstop, 0.04)

func _draw_scars() -> void:
	for sc in scars:
		if int(sc.get("kind", 0)) == 0:
			draw_circle(Vector2(sc.x, sc.y), 7.0, Color(0.04, 0.03, 0.03, 0.55))
			draw_circle(Vector2(sc.x, sc.y), 4.0, Color(0.08, 0.06, 0.05, 0.6))
			for _k in range(5):
				var _a: float = TAU * _k / 5.0
				draw_line(Vector2(sc.x, sc.y), Vector2(sc.x + cos(_a) * 9.0, sc.y + sin(_a) * 9.0), Color(0.05, 0.04, 0.03, 0.4), 1.0)
		else:
			for _k in range(6):
				var _dx: float = sc.x + sin(sc.x + _k * 2.3) * 6.0
				var _dy: float = sc.y + cos(sc.y + _k * 1.7) * 5.0
				draw_rect(Rect2(_dx, _dy, 1.5, 1.5), Color(0.4, 0.42, 0.48, 0.5))

func _draw_parts() -> void:
	for pt in parts:
		var f: float = clamp(1.0 - pt.t / pt.life, 0.0, 1.0)
		var c: Color = pt.col
		if pt.get("ring", false):
			var rr2: float = pt.r + (1.0 - f) * 8.0
			draw_arc(Vector2(pt.x, pt.y), rr2, 0.0, TAU, 16, Color(c.r, c.g, c.b, f * 0.8), 1.5)
		else:
			var rr: float = pt.r * f
			draw_rect(Rect2(pt.x - rr, pt.y - rr, rr * 2.0, rr * 2.0), Color(c.r, c.g, c.b, f))

func use_item2() -> void:
	if not (state == St.PLAY or state == St.VIRUS or state == St.BOSS):
		return
	if item2_cd > 0.0:
		if audio: audio.sfx("deny")
		return
	item2_cd = item2_max
	shield_t = 3.0
	if audio: audio.sfx("gate")
	_flash("ЩИТ АКТИВЕН")
	if is_instance_valid(player): player.inv = max(player.inv, 3.0)

func use_active_item() -> void:
	if not (state == St.PLAY or state == St.VIRUS or state == St.BOSS):
		return
	if item_cd > 0.0:
		if audio: audio.sfx("deny")
		return
	if not is_instance_valid(player):
		return
	item_cd = item_max
	shake = max(shake, 0.55)
	hitstop = max(hitstop, 0.05)
	if audio: audio.sfx("gate")
	_flash("Р­РњРИ-ГРАНАТА")
	var rad := 62.0
	for e in enemies.duplicate():
		if is_instance_valid(e) and e.hacked <= 0.0 and e.position.distance_to(player.position) < rad:
			e.hurt(26.0)
	for b in bullets.duplicate():
		if is_instance_valid(b) and b.team == "enemy" and b.position.distance_to(player.position) < rad:
			remove_bullet(b)
	var ptx := int(floor(player.position.x / TILE))
	var pty := int(floor(player.position.y / TILE))
	var broke_any := false
	for ddy in range(-3, 4):
		for ddx in range(-3, 4):
			if tile_at(ptx+ddx, pty+ddy) == "w":
				set_tile(ptx+ddx, pty+ddy, ".")
				broke_walls[_hid(ptx+ddx, pty+ddy)] = true
				scars.append({"x": (ptx+ddx)*TILE+TILE*0.5, "y": (pty+ddy)*TILE+TILE*0.5, "kind": 1})
				broke_any = true
	if broke_any:
		say("Проход взорван! Граната ломает слабые стены.")
	if virus != null and is_instance_valid(virus) and virus.position.distance_to(player.position) < rad:
		virus.hurt(18.0)
	if boss != null and is_instance_valid(boss) and boss.position.distance_to(player.position) < rad:
		boss.hurt(18.0)
	for i in range(18):
		var a: float = TAU * i / 18.0
		parts.append({"x": player.position.x, "y": player.position.y, "vx": cos(a) * 150.0, "vy": sin(a) * 150.0, "t": 0.0, "life": 0.4, "col": Color(0.6, 0.95, 1.0), "r": 2.2})

func _draw_postfx(W: float, H: float) -> void:
	var amb: Color = (pal.get(style, pal["clean"]))["ac"]
	# always-on soft light pooled under the player, grounds the scene
	if is_instance_valid(player):
		var pp: Vector2 = player.position
		draw_circle(pp, 30.0, Color(amb.r, amb.g, amb.b, 0.05))
		draw_circle(pp, 18.0, Color(amb.r, amb.g, amb.b, 0.05))
	# bloom around bright emitters
	for lp in lamps:
		var fl: float = 0.6 + 0.4 * sin(menu_t * 6.0 + lp.x)
		draw_circle(lp, 12.0 + fl * 4.0, Color(1.0, 0.95, 0.7, 0.06 * fl))
		draw_circle(lp, 5.0, Color(1.0, 1.0, 0.85, 0.10 * fl))
	for b in bullets:
		if is_instance_valid(b):
			draw_circle(b.position, 5.5, Color(b.col.r, b.col.g, b.col.b, 0.14))
	# drifting dust motes catch the light (ambient life in the air)
	var motes: int = 10 + int(zone_glitch.get(zone, 0.0) * 8.0)
	for i in range(motes):
		var mx: float = fmod(i * 61.0 + menu_t * (5.0 + float(i % 3) * 3.0), W)
		var my: float = fmod(i * 47.0 + sin(menu_t * 0.5 + i) * 8.0 + menu_t * 3.0, H)
		var ma: float = 0.05 + 0.05 * sin(menu_t * 2.0 + i)
		draw_rect(Rect2(mx, my, 1.0, 1.0), Color(amb.r, amb.g, amb.b, ma))
	# gentle CRT scanlines
	if not reduce_shake:
		var yy: float = 0.0
		while yy < H:
			draw_rect(Rect2(0.0, yy, W, 1.0), Color(0.0, 0.0, 0.0, 0.055))
			yy += 3.0
	# faint zone-tinted bloom lift
	draw_rect(Rect2(0, 0, W, H), Color(amb.r, amb.g, amb.b, 0.02))

func _draw_vignette(W: float, H: float) -> void:
	# No permanent vignette: only short gameplay feedback remains.
	if shake > 0.2 and not reduce_shake:
		var sa: float = clamp((shake - 0.2) * 0.6, 0.0, 0.25)
		draw_rect(Rect2(0, 0, W, H), Color(1.0, 0.15, 0.2, sa * 0.30))
		draw_rect(Rect2(2, 0, W, 1), Color(1.0, 0.1, 0.15, sa))
		draw_rect(Rect2(-2, H - 1, W, 1), Color(0.1, 0.6, 1.0, sa))
	if dmg_flash > 0.0:
		var df: float = clamp(dmg_flash, 0.0, 1.0)
		var dd: Vector2 = dmg_dir
		var thick: float = 40.0 * df
		if dd.x > 0.4:
			draw_rect(Rect2(W - thick, 0, thick, H), Color(1.0, 0.1, 0.15, 0.35 * df))
		if dd.x < -0.4:
			draw_rect(Rect2(0, 0, thick, H), Color(1.0, 0.1, 0.15, 0.35 * df))
		if dd.y > 0.4:
			draw_rect(Rect2(0, H - thick, W, thick), Color(1.0, 0.1, 0.15, 0.35 * df))
		if dd.y < -0.4:
			draw_rect(Rect2(0, 0, W, thick), Color(1.0, 0.1, 0.15, 0.35 * df))

func _start_boss_intro(b) -> void:
	boss_intro_ref = b
	boss_intro_t = 0.0
	boss_intro_name = _boss_display_name(b.arch)
	boss_intro_line = b.say_text
	state = St.BOSS_INTRO
	shake = 0.4
	if audio: audio.play_music("bossintro")

func _end_boss_intro() -> void:
	if state != St.BOSS_INTRO:
		return
	state = St.PLAY
	pending_boss = null
	boss_intro_ref = null
	shake = max(shake, 0.5)
	if audio: audio.sfx("bossroar")
	if audio: audio.play_music("boss")
	_flash("\u0411\u041e\u0419!")

func _boss_display_name(arch: String) -> String:
	match arch:
		"security": return "\u0411\u041e\u0422-\u0421\u0415\u041a\u042c\u042e\u0420\u0418\u0422\u0418"
		"golem": return "\u041f\u0420\u0418\u041d\u0422\u0415\u0420-\u0413\u041e\u041b\u0415\u041c"
		"secretary": return "\u0421\u0415\u041a\u0420\u0415\u0422\u0410\u0420\u042c-\u041c\u0410\u0422\u0420\u0401\u0428\u041a\u0410"
		"admin": return "\u0410\u0414\u041c\u0418\u041d\u0418\u0421\u0422\u0420\u0410\u0422\u041e\u0420"
		"hive": return "\u0420\u041e\u0419-\u0423\u041b\u0415\u0419"
	return "\u0417\u0410\u0420\u0410\u0416\u0401\u041d\u041d\u042b\u0419 \u0411\u041e\u0421\u0421"

func _draw_boss_intro() -> void:
	var W: float = COLS * TILE
	var H: float = ROWS * TILE
	var ap: float = clamp(boss_intro_t / 0.4, 0.0, 1.0)
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.02, 0.05, 0.42 * ap))
	var bh: float = 22.0
	draw_rect(Rect2(0, 0, W, bh), Color(0, 0, 0, 0.85 * ap))
	draw_rect(Rect2(0, H - bh, W, bh), Color(0, 0, 0, 0.85 * ap))
	draw_rect(Rect2(0, bh, W, 1), Color(1.0, 0.3, 0.3, ap))
	draw_rect(Rect2(0, H - bh - 1, W, 1), Color(1.0, 0.3, 0.3, ap))
	if is_instance_valid(boss_intro_ref):
		var bp: Vector2 = boss_intro_ref.position
		var ringr: float = 20.0 + 6.0 * sin(boss_intro_t * 4.0)
		draw_arc(bp, ringr, 0.0, TAU, 28, Color(1.0, 0.3, 0.3, 0.5 * ap), 1.5)
	CutScenes.ctext(self, boss_intro_name, W * 0.5, 15, 13, Color(1.0, 0.85, 0.85, ap))
	var full: String = boss_intro_line
	var n: int = clampi(int(boss_intro_t * 34.0), 0, full.length())
	CutScenes.ctext(self, full.substr(0, n), W * 0.5, H - 13, 8, Color(1.0, 0.7, 0.65, ap))
	if int(menu_t * 2.0) % 2 == 0 and boss_intro_t > 1.0:
		draw_string(font, Vector2(W - 82, H - 4), "SPACE - \u0432 \u0431\u043e\u0439", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.85, 0.45, 0.45))
