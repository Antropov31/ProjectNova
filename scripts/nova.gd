extends Node2D

# Nova - your robot companion. Now she FIGHTS with you: press E near her (off
# cooldown) to fire an EMP pulse that damages and briefly stuns nearby enemies.
# You come to rely on her... which is the point. When the virus takes her at the
# core, losing that pulse is a real mechanical loss, not just a sad line.

var game
var player
var t: float = 0.0
var ping_t: float = 0.0
var infected: bool = false
var menu_mode: bool = false
var glitch_kick: float = 0.0

var pulse_cd: float = 0.0
var pulse_anim: float = 0.0
const PULSE_MAX_CD: float = 5.0
var pulse_bonus: float = 0.0
const PULSE_RADIUS: float = 46.0

var transforming: bool = false
var tf: float = 0.0
var transform_done: bool = false

func _process(delta: float) -> void:
	t += delta
	ping_t = max(0.0, ping_t - delta)
	glitch_kick = max(0.0, glitch_kick - delta)
	pulse_cd = max(0.0, pulse_cd - delta)
	pulse_anim = max(0.0, pulse_anim - delta)

	if transforming:
		tf = min(1.0, tf + delta / 3.2)
		if tf >= 1.0 and not transform_done:
			transform_done = true
		queue_redraw()
		return

	if menu_mode:
		queue_redraw()
		return

	if player == null or not is_instance_valid(player):
		return
	var off := Vector2(-player.facing * 12.0, -11.0)
	var target: Vector2 = player.position + off + Vector2(0, sin(t * 3.0) * 1.5)
	var k: float = 1.0 - exp(-10.0 * delta)
	position = position.lerp(target, k)
	queue_redraw()

func ping() -> void:
	ping_t = 0.5

func glitch() -> void:
	glitch_kick = 0.25

func can_pulse() -> bool:
	return not infected and not menu_mode and pulse_cd <= 0.0

func do_pulse() -> void:
	pulse_cd = max(2.0, PULSE_MAX_CD - pulse_bonus)
	pulse_anim = 0.45
	ping()

func start_transform() -> void:
	transforming = true
	tf = 0.0

func _glitch_off() -> Vector2:
	var g: float = 0.0
	if game != null:
		g = game.glitch_level
	g = max(g, glitch_kick * 4.0)
	if g <= 0.0:
		return Vector2.ZERO
	if randf() < g * 0.5:
		return Vector2(randf_range(-2.0, 2.0), randf_range(-1.0, 1.0)) * g
	return Vector2.ZERO

func _draw() -> void:
	if transforming:
		_draw_transform()
		return
	var o := _glitch_off()
	# EMP pulse expanding ring
	if pulse_anim > 0.0:
		var pf: float = 1.0 - pulse_anim / 0.45
		draw_arc(Vector2.ZERO, 6.0 + pf * PULSE_RADIUS, 0.0, TAU, 40, Color(0.5, 1.0, 0.95, pulse_anim * 2.0), 2.0)
		draw_arc(Vector2.ZERO, 3.0 + pf * PULSE_RADIUS * 0.7, 0.0, TAU, 32, Color(0.8, 1.0, 1.0, pulse_anim), 1.0)
	if ping_t > 0.0:
		var f: float = 1.0 - ping_t / 0.5
		draw_arc(Vector2.ZERO, 4.0 + f * 20.0, 0.0, TAU, 24, Color(0.4, 1.0, 0.9, ping_t))
	draw_circle(Vector2(0, 6), 4.0, Color(0, 0, 0, 0.2))
	draw_circle(o, 7.0, Color(0.3, 0.9, 0.9, 0.16))
	# hover thruster
	var th := 0.5 + 0.5 * sin(t * 12.0)
	draw_rect(Rect2(o.x - 2, o.y + 4, 4, 2), Color(0.3, 0.8, 1.0, 0.4 + 0.3 * th))
	# rounded shell (more pixels, plated)
	draw_rect(Rect2(o.x - 5, o.y - 5, 10, 9), Color(0.12, 0.5, 0.55))
	draw_rect(Rect2(o.x - 5, o.y - 5, 10, 2), Color(0.35, 0.95, 0.98))
	draw_rect(Rect2(o.x - 4, o.y - 3, 8, 5), Color(0.16, 0.62, 0.66))
	draw_rect(Rect2(o.x - 5, o.y - 5, 1, 9), Color(0.08, 0.35, 0.4))
	draw_rect(Rect2(o.x + 4, o.y - 5, 1, 9), Color(0.08, 0.35, 0.4))
	draw_rect(Rect2(o.x - 4, o.y + 2, 8, 1), Color(0.08, 0.3, 0.35))
	# side fins
	draw_rect(Rect2(o.x - 7, o.y - 1, 2, 3), Color(0.2, 0.7, 0.72))
	draw_rect(Rect2(o.x + 5, o.y - 1, 2, 3), Color(0.2, 0.7, 0.72))
	# eye
	var look: Vector2 = Vector2(sin(t * 1.7), 0) * 1.2
	if game != null and game.glitch_level > 0.4 and int(t * 8.0) % 7 == 0:
		look = Vector2(randf_range(-2, 2), randf_range(-1, 1))
	draw_rect(Rect2(o.x - 3, o.y - 3, 6, 4), Color(0.05, 0.15, 0.18))
	var eye_col := Color(0.5, 1.0, 0.95)
	if game != null and game.glitch_level > 0.5 and int(t * 6.0) % 5 == 0:
		eye_col = Color(1.0, 0.3, 0.3)
	if pulse_cd <= 0.0 and not menu_mode:
		eye_col = Color(0.6, 1.0, 0.7)  # ready to pulse: bright green tint
	draw_circle(o + look, 1.8, eye_col)
	draw_circle(o + look, 0.9, Color(1, 1, 1))
	# antenna
	draw_line(o + Vector2(0, -5), o + Vector2(0, -8), Color(0.3, 0.8, 0.85), 1.0)
	draw_circle(o + Vector2(0, -8), 1.2, eye_col)
	# small cooldown pip
	if not menu_mode and pulse_cd > 0.0:
		var frac: float = 1.0 - pulse_cd / PULSE_MAX_CD
		draw_arc(o, 9.0, -PI/2.0, -PI/2.0 + TAU * frac, 16, Color(0.4, 0.9, 0.9, 0.5), 1.0)

func _draw_transform() -> void:
	# morph from small teal bot into a large, jagged red-black horror
	var p := tf
	var shake := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * p * 4.0
	var size: float = lerp(6.0, 28.0, p)
	var teal := Color(0.16, 0.6, 0.65)
	var redblack := Color(0.10, 0.02, 0.04)
	var body: Color = teal.lerp(redblack, p)
	var accent: Color = Color(0.4, 1.0, 0.9).lerp(Color(1.0, 0.15, 0.2), p)
	# growing red halo
	draw_circle(shake, size + 8.0 * p, Color(1.0, 0.1, 0.15, 0.18 * p))
	# jagged emerging body
	var poly := PackedVector2Array()
	var spikes := 9
	for i in range(spikes):
		var a: float = TAU * i / spikes + t * 2.0 * p
		var rr: float = size * (0.8 + 0.4 * abs(sin(i * 2.3 + t)) * p)
		poly.append(shake + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(poly, body)
	# cabling tearing loose
	if p > 0.35:
		for i in range(5):
			var a: float = TAU * i / 5.0 + t
			var d := Vector2(cos(a), sin(a))
			draw_line(shake + d * size, shake + d * (size + 7.0 * p), Color(0.5, 0.05, 0.1), 1.5)
	# infection seams
	for i in range(4):
		var yy: float = shake.y - size + (size * 2.0) * (float(i) / 3.0)
		draw_rect(Rect2(shake.x - size, yy, size * 2.0, 1.0), Color(accent.r, accent.g, accent.b, 0.5 + 0.5 * p))
	# eye tearing open
	var eye_r: float = lerp(2.0, 10.0, p)
	draw_circle(shake, eye_r, Color(0.2, 0.0, 0.0))
	draw_circle(shake, eye_r * 0.6, Color(1.0, 0.2 + 0.3 * sin(t * 20.0), 0.15))
	if p > 0.6:
		draw_circle(shake, eye_r * 0.28, Color(1.0, 0.95, 0.6))
