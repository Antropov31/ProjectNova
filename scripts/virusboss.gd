extends Node2D

# The main computer, infected. A huge red corrupted screen bolted to the back
# wall, oozing writhing virus tentacles. Phase 1 of the finale. It taunts you.

var game
var player
var hp: float = 260.0
var max_hp: float = 260.0
var radius: float = 26.0
var hurt_t: float = 0.0
var t: float = 0.0

var fire_cd: float = 1.4
var sweep_cd: float = 4.0
var beam_cd: float = 7.0
var mouth: float = 0.0
var say_t: float = 0.0
var say_text: String = ""
var tendrils: Array = []

var lines: Array = [
	"КОМПЬЮТЕР: ты опоздал, мясо. я уже везде.",
	"КОМПЬЮТЕР: твоя железка тоже станет мной. дай срок.",
	"КОМПЬЮТЕР: выключить меня? я и есть этот завод.",
]

func _ready() -> void:
	for i in range(7):
		tendrils.append({"a": TAU * i / 7.0, "len": randf_range(8.0, 16.0), "ph": randf() * TAU})
	_say(lines[0])

func _say(s: String) -> void:
	say_text = s
	say_t = 3.2
	if game != null and game.audio: game.audio.sfx("virus")

func _enraged() -> bool:
	return hp < max_hp * 0.4

func _process(delta: float) -> void:
	if game == null or player == null or not is_instance_valid(player):
		return
	if game.state != game.St.VIRUS:
		return
	t += delta
	hurt_t = max(0.0, hurt_t - delta)
	say_t = max(0.0, say_t - delta)
	mouth = 0.5 + 0.5 * sin(t * 3.0)
	var rage := 1.4 if _enraged() else 1.0

	fire_cd -= delta
	if fire_cd <= 0.0:
		fire_cd = 1.3 / rage
		_spit()
	sweep_cd -= delta
	if sweep_cd <= 0.0:
		sweep_cd = 4.5
		_ring()
		if randf() < 0.5: _say(lines[randi() % lines.size()])
	# 3rd attack, enraged only: a raking floor beam of red bolts
	if _enraged():
		beam_cd -= delta
		if beam_cd <= 0.0:
			beam_cd = 5.0
			var from: Vector2 = position + Vector2(0, radius * 0.4)
			var base: Vector2 = (player.position - from).normalized()
			for i in range(12):
				var sp := deg_to_rad(-40.0 + 7.0 * i)
				game.spawn_bullet(from, base.rotated(sp), "enemy", 1.0, Color(1.0,0.15,0.2), 60.0 + i*4.0, 4.0)
	queue_redraw()

func _spit() -> void:
	var from: Vector2 = position + Vector2(0, radius * 0.4)
	var base: Vector2 = (player.position - from).normalized()
	for i in range(3):
		var sp := deg_to_rad(-16.0 + 16.0 * i)
		game.spawn_bullet(from, base.rotated(sp), "enemy", 1.0, Color(1.0, 0.3, 0.3), 96.0, 3.0)
	if game.audio: game.audio.sfx("blip")

func _ring() -> void:
	var from: Vector2 = position + Vector2(0, radius * 0.4)
	var n := 12
	for i in range(n):
		var a := TAU * i / n
		game.spawn_bullet(from, Vector2(cos(a), sin(a)), "enemy", 1.0, Color(1.0, 0.4, 0.25), 78.0, 3.0)

func hurt(d: float) -> void:
	hp -= d
	hurt_t = 0.07
	if game.audio: game.audio.sfx("bosshit")
	if hp <= 0.0:
		hp = 0.0
		game.virus_defeated()

func _draw() -> void:
	var r: float = radius
	var shake := Vector2.ZERO
	if _enraged():
		shake = Vector2(randf_range(-1,1), randf_range(-1,1))
	# --- writhing virus tentacles behind the screen ---
	for td in tendrils:
		var a: float = td["a"] + sin(t * 1.2 + td["ph"]) * 0.5
		var p0: Vector2 = shake + Vector2(cos(a), sin(a)) * (r * 0.7)
		var seg: int = int(td["len"])
		var p1: Vector2 = p0 + Vector2(cos(a), sin(a)) * seg + Vector2(sin(t*3.0+td["ph"])*4.0, cos(t*2.0)*3.0)
		var p2: Vector2 = p1 + Vector2(cos(a + 0.7), sin(a + 0.7)) * (seg * 0.7)
		draw_line(p0, p1, Color(0.6, 0.05, 0.1), 3.0)
		draw_line(p1, p2, Color(0.8, 0.1, 0.15), 2.0)
		draw_circle(p2, 2.0, Color(1.0, 0.3, 0.2))
		draw_circle(p2, 1.0, Color(1.0, 0.8, 0.4))
	# --- red aura ---
	var pulse: float = 0.5 + 0.5 * sin(t * 6.0)
	draw_circle(shake, r + 6.0 + pulse * 4.0, Color(1.0, 0.1, 0.12, 0.14))
	if int(t * 12.0) % 3 == 0:
		var sang: float = randf() * TAU
		var sp0: Vector2 = shake + Vector2(cos(sang), sin(sang)) * (r + 2.0)
		var sp1: Vector2 = sp0 + Vector2(cos(sang), sin(sang)) * randf_range(3.0, 8.0)
		draw_line(sp0, sp1, Color(1.0, 0.6, 0.7, 0.8), 1.0)
		draw_circle(sp1, 1.0, Color(1.0, 0.9, 0.8))
	# --- shared corrupted-computer sprite (matches the intro) ---
	const CS = preload("res://scripts/cutscenes.gd")
	var _et: Vector2 = (player.position - position) if is_instance_valid(player) else Vector2.ZERO
	CS.draw_computer_virus(self, shake.x, shake.y, r, t, 1.0, _et)
	if hurt_t > 0.0:
		draw_rect(Rect2(shake.x - r, shake.y - r, r*2, r*2), Color(1,1,1,0.35))
	# --- speech bubble ---
	if say_t > 0.0 and say_text != "":
		var tw: float = say_text.length() * 4.2 + 8.0
		var bx: float = clamp(position.x - tw*0.5, 2.0, game.COLS*game.TILE - tw - 2.0)
		var by: float = position.y - r - 16.0
		draw_rect(Rect2(bx - position.x, by - position.y, tw, 11), Color(0.12,0.02,0.03,0.92))
		draw_rect(Rect2(bx - position.x, by - position.y, tw, 1), Color(1.0,0.3,0.3,0.8))
		draw_string(game.font, Vector2(bx - position.x + 4, by - position.y + 8), say_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1.0,0.7,0.7))
