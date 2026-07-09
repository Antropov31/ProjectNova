extends Node2D

# Infected Nova. Turns YOUR chosen upgrades against you. A corrupted robot
# shell: her old teal core cracked open and overtaken by a red-black parasite,
# trailing broken cabling, one huge fractured eye.
#
# Horror beat + real dilemma: every so often her true self surfaces (lucid).
# She freezes and begs you to end it. If you land the KILLING blow while she is
# lucid, you get the MERCIFUL ending. If you shatter her while she rages, you
# get the grim one. Lucid also cuts short early if you hesitate too long.

var game
var player
var hp: float = 400.0
var max_hp: float = 400.0
var radius: float = 15.0
var hurt_t: float = 0.0
var t: float = 0.0
var died_lucid: bool = false

var fire_cd: float = 1.2
var dash_cd: float = 3.0
var charge_cd: float = 2.6
var turret_cd: float = 2.0
var sweep_cd: float = 6.0
var move_cd: float = 0.0
var target: Vector2 = Vector2.ZERO
var dashing: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO
var tendrils: Array = []
var shards: Array = []

var b_bolts: int = 1
var b_dash: bool = false
var b_charge: bool = false
var b_turret: bool = false
var phase2: bool = false

var lucid: float = 0.0
var lucid_cd: float = 7.0
var lucid_lines: Array = [
	"NOVA: это... это правда я. убей меня. ПОКА Я МОГУ ПРОСИТЬ.",
	"NOVA: я держу его. стреляй. сейчас. СЕЙЧАС, пожалуйста.",
	"NOVA: не жалей. я не хочу быть этим. заверши. умоляю.",
	"NOVA: прости. добей меня, друг. это единственный выход.",
]

func _ready() -> void:
	target = position
	for i in range(5):
		tendrils.append(randf() * TAU)
	for i in range(4):
		shards.append({"a": TAU * i / 4.0, "d": randf_range(20.0, 28.0), "sp": randf_range(0.5, 1.3), "sz": randf_range(3.0, 6.0)})

func _enraged() -> bool:
	return hp < max_hp * 0.5

func _process(delta: float) -> void:
	if game == null or player == null or not is_instance_valid(player):
		return
	if game.state != game.St.BOSS:
		return
	t += delta
	hurt_t = max(0.0, hurt_t - delta)
	lucid = max(0.0, lucid - delta)

	lucid_cd -= delta
	if lucid_cd <= 0.0 and lucid <= 0.0 and hp > max_hp * 0.1:
		lucid_cd = randf_range(8.0, 13.0)
		lucid = 2.4
		game.nova_lucid(lucid_lines[randi() % lucid_lines.size()])

	if lucid > 0.0:
		# frozen, trembling, pleading, defenceless
		position += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 1.3
		queue_redraw()
		return

	var rage := 1.5 if _enraged() else 1.0
	var W: float = game.COLS * game.TILE
	var H: float = game.ROWS * game.TILE
	if dashing > 0.0:
		dashing -= delta
		position += dash_dir * 210.0 * rage * delta
	else:
		move_cd -= delta
		if move_cd <= 0.0:
			move_cd = 1.6
			target = Vector2(randf_range(radius + 8.0, W - radius - 8.0), randf_range(radius + 8.0, H * 0.55))
		position = position.lerp(target, clamp(delta * 1.4 * rage, 0.0, 1.0))
		if b_dash:
			dash_cd -= delta
			if dash_cd <= 0.0:
				dash_cd = 3.2 / rage
				dash_dir = (player.position - position).normalized()
				dashing = 0.32

	position.x = clamp(position.x, radius, W - radius)
	position.y = clamp(position.y, radius, H - radius)

	fire_cd -= delta
	if fire_cd <= 0.0:
		fire_cd = 1.1 / rage
		_fan()
	if b_charge:
		charge_cd -= delta
		if charge_cd <= 0.0:
			charge_cd = 2.6
			var d: Vector2 = (player.position - position).normalized()
			game.spawn_bullet(position + d * (radius + 3.0), d, "enemy", 3.0, Color(1.0, 0.4, 0.8), 80.0, 5.0)
	if b_turret:
		turret_cd -= delta
		if turret_cd <= 0.0:
			turret_cd = 2.2
			var n := 14
			for i in range(n):
				var a: float = TAU * i / n + t
				var d := Vector2(cos(a), sin(a))
				game.spawn_bullet(position + d * (radius + 2.0), d, "enemy", 1.0, Color(1.0, 0.55, 0.2), 88.0, 3.0)
	# THIRD attack, only when enraged: a rotating spiral scythe
	if _enraged():
		sweep_cd -= delta
		if sweep_cd <= 0.0:
			sweep_cd = 3.4
			for arm in range(2):
				for i in range(8):
					var a: float = t * 2.0 + arm * PI + i * 0.14
					var d := Vector2(cos(a), sin(a))
					game.spawn_bullet(position + d * (radius + 2.0), d, "enemy", 1.0, Color(0.9, 0.2, 0.4), 70.0 + i * 4.0, 3.0)
	queue_redraw()

func _fan() -> void:
	var base: Vector2 = (player.position - position).normalized()
	var bolts: int = max(1, b_bolts)
	if _enraged():
		bolts += 1
	for i in range(bolts):
		var sp: float = 0.0
		if bolts > 1:
			sp = deg_to_rad(-12.0 * (bolts - 1) / 2.0 + 12.0 * i)
		var d: Vector2 = base.rotated(sp)
		game.spawn_bullet(position + d * (radius + 3.0), d, "enemy", 1.0, Color(1.0, 0.35, 0.3), 110.0, 3.0)
	if game.audio: game.audio.sfx("blip")

func hurt(d: float) -> void:
	if lucid > 0.0:
		d *= 1.6
	hp -= d
	if not phase2 and hp < max_hp * 0.5 and hp > 0.0:
		phase2 = true
		game.shake = max(game.shake, 0.9)
		if game.hitstop != null: game.hitstop = max(game.hitstop, 0.12)
		game._flash("ОНА РАСКРЫВАЕТСЯ. ФАЗА 2.")
		if game.audio: game.audio.sfx("transform")
		for i in range(20):
			var a: float = TAU * i / 20.0
			game.spawn_bullet(position + Vector2(cos(a), sin(a)) * (radius + 2.0), Vector2(cos(a), sin(a)), "enemy", 1.0, Color(1.0, 0.3, 0.4), 100.0, 3.0)
	hurt_t = 0.07
	if game.audio: game.audio.sfx("bosshit")
	if hp <= 0.0:
		hp = 0.0
		died_lucid = lucid > 0.0
		game.boss_killed(died_lucid)

func _draw() -> void:
	var r: float = radius
	var lm: float = clamp(lucid / 2.4, 0.0, 1.0)  # lucid mix
	var pulse: float = 0.5 + 0.5 * sin(t * 8.0)
	var shake := Vector2.ZERO
	if _enraged() or lucid > 0.0:
		shake = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (1.0 + lm * 1.5)

	# --- outer aura ---
	var aura := Color(1.0, 0.08, 0.14).lerp(Color(0.4, 1.0, 0.9), lm)
	draw_circle(shake, r + 6.0 + pulse * 4.0, Color(aura.r, aura.g, aura.b, 0.12 + 0.16 * lm))
	draw_circle(Vector2(0, r * 0.8) + shake, r * 1.1, Color(0, 0, 0, 0.3))
	for sh in shards:
		var sa: float = sh["a"] + t * sh["sp"]
		var sd: float = sh["d"] + sin(t * 2.0 + sh["a"]) * 3.0
		var sp2: Vector2 = shake + Vector2(cos(sa), sin(sa)) * sd
		var ssz: float = sh["sz"]
		var scol: Color = Color(0.16, 0.5, 0.55).lerp(Color(0.6, 0.1, 0.15), 0.4 + 0.3 * sin(t + sh["a"]))
		draw_colored_polygon(PackedVector2Array([sp2 + Vector2(-ssz, 0), sp2 + Vector2(0, -ssz*0.7), sp2 + Vector2(ssz, 0), sp2 + Vector2(0, ssz*0.7)]), scol)
		draw_line(sp2 + Vector2(-ssz, 0), sp2 + Vector2(ssz, 0), Color(1.0, 0.3, 0.3, 0.5), 1.0)

	# --- broken cabling / tendrils writhing out the back ---
	for i in range(tendrils.size()):
		var base_a: float = tendrils[i] + sin(t * 1.5 + i) * 0.4
		var p0: Vector2 = shake + Vector2(cos(base_a), sin(base_a)) * (r * 0.8)
		var p1: Vector2 = p0 + Vector2(cos(base_a), sin(base_a)) * (6.0 + sin(t * 3.0 + i) * 3.0)
		var p2: Vector2 = p1 + Vector2(cos(base_a + 0.6), sin(base_a + 0.6)) * 5.0
		var tcol := Color(0.5, 0.05, 0.1).lerp(Color(0.2, 0.6, 0.6), lm)
		draw_line(p0, p1, tcol, 2.0)
		draw_line(p1, p2, tcol, 1.5)
		draw_circle(p2, 1.5, Color(1.0, 0.3, 0.2).lerp(Color(0.4, 1.0, 0.9), lm))

	# --- fractured shell: remnants of teal Nova + red-black parasite ---
	var shell_teal := Color(0.14, 0.5, 0.55).lerp(Color(0.2, 0.7, 0.7), lm)
	var parasite := Color(0.10, 0.02, 0.04)
	if hurt_t > 0.0:
		parasite = Color(1, 1, 1)
		shell_teal = Color(1, 1, 1)
	# jagged asymmetric body via polygon
	var body := PackedVector2Array()
	var spikes := 9
	for i in range(spikes):
		var a: float = TAU * i / spikes + t * (0.8 if _enraged() else 0.3)
		var rr: float = r * (0.85 + 0.35 * abs(sin(i * 2.3 + t)))
		body.append(shake + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(body, parasite)
	# surviving teal plates (left side, the part still 'her')
	draw_colored_polygon(PackedVector2Array([
		shake + Vector2(-r, -r * 0.3),
		shake + Vector2(-r * 0.2, -r * 0.5),
		shake + Vector2(-r * 0.1, r * 0.4),
		shake + Vector2(-r * 0.9, r * 0.3)]), shell_teal)
	# glowing infection cracks
	var crack := Color(1.0, 0.2, 0.25).lerp(Color(0.5, 1.0, 0.95), lm)
	for i in range(4):
		var a1: float = t * 0.5 + i * 1.7
		var cp0 := shake + Vector2(cos(a1), sin(a1)) * (r * 0.2)
		var cp1 := shake + Vector2(cos(a1), sin(a1)) * (r * 0.9)
		draw_line(cp0, cp1, Color(crack.r, crack.g, crack.b, 0.5 + 0.5 * pulse), 1.5)

	# --- the eye: huge, cracked, tracking you ---
	var eye := Vector2.ZERO
	if is_instance_valid(player):
		eye = (player.position - position).normalized()
	draw_circle(shake, r * 0.5, Color(0.15, 0.0, 0.0).lerp(Color(0.04, 0.18, 0.2), lm))
	var iris := Color(1.0, 0.15 + 0.3 * pulse, 0.1).lerp(Color(0.4, 1.0, 0.9), lm)
	draw_circle(shake, r * 0.34, iris)
	draw_circle(shake + eye * r * 0.28, r * 0.16, Color(0.1, 0.0, 0.0))
	draw_circle(shake + eye * r * 0.28, r * 0.07, Color(1.0, 0.95, 0.6))
	# eye crack
	draw_line(shake + Vector2(-r * 0.3, -r * 0.4), shake + Vector2(r * 0.1, r * 0.2), Color(0.0, 0.0, 0.0, 0.6), 1.0)
	for i in range(3):
		var dph: float = fmod(t * 1.5 + i * 0.7, 1.0)
		var dx: float = shake.x + (i - 1) * r * 0.5
		draw_circle(Vector2(dx, shake.y + r * 0.6 + dph * r * 0.8), 1.5 * (1.0 - dph), Color(0.7, 0.05, 0.12, 0.7 * (1.0 - dph)))

	# --- pleading glow when lucid ---
	if lucid > 0.0:
		draw_arc(shake, r + 3.0, 0.0, TAU, 28, Color(0.6, 1.0, 0.95, 0.6 + 0.4 * pulse), 1.5)
