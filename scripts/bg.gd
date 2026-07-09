extends Node2D

# Screen-space parallax background (lives inside a CanvasLayer).
# game.gd feeds it the camera position each frame to scroll the layers.

var cam_pos: Vector2 = Vector2.ZERO
var screen: Vector2 = Vector2(1152, 648)
var t: float = 0.0
var top_col: Color = Color(0.05, 0.07, 0.12)
var bot_col: Color = Color(0.10, 0.06, 0.16)
var accent: Color = Color(0.2, 0.9, 0.8)
var stars: Array = []

func _ready() -> void:
	for i in range(70):
		stars.append(Vector2(randf() * 2000.0, randf() * 1400.0))

func set_theme(tc: Color, bc: Color, ac: Color) -> void:
	top_col = tc
	bot_col = bc
	accent = ac
	queue_redraw()

func _process(delta: float) -> void:
	t += delta

func _draw() -> void:
	# vertical gradient sky via horizontal bands
	var bands: int = 24
	for i in range(bands):
		var f: float = float(i) / float(bands - 1)
		var c: Color = top_col.lerp(bot_col, f)
		draw_rect(Rect2(0, screen.y * f, screen.x, screen.y / bands + 1.0), c)

	# far parallax: soft glowing columns (server racks silhouette)
	var off1: float = fmod(cam_pos.x * 0.15, 260.0)
	var x: float = -off1 - 130.0
	while x < screen.x + 130.0:
		var h: float = screen.y * 0.55
		var top: float = screen.y - h
		draw_rect(Rect2(x, top, 90.0, h), Color(top_col.r + 0.03, top_col.g + 0.04, top_col.b + 0.06, 0.7))
		# blinking indicator lights
		for j in range(6):
			var ly: float = top + 30.0 + j * 60.0
			var blink: float = 0.4 + 0.6 * absf(sin(t * 2.0 + x * 0.05 + j))
			draw_circle(Vector2(x + 45.0, ly), 3.5, Color(accent.r, accent.g, accent.b, 0.5 * blink))
		x += 260.0

	# mid parallax: neon horizon line + grid floor fade
	var horizon: float = screen.y * 0.62
	draw_line(Vector2(0, horizon), Vector2(screen.x, horizon), Color(accent.r, accent.g, accent.b, 0.25), 2.0)
	var off2: float = fmod(cam_pos.x * 0.35, 120.0)
	var gx: float = -off2
	while gx < screen.x + 120.0:
		draw_line(Vector2(gx, horizon), Vector2(gx, screen.y), Color(accent.r, accent.g, accent.b, 0.06), 1.0)
		gx += 120.0

	# drifting dust / stars (very slow parallax)
	for s in stars:
		var px: float = fmod(s.x - cam_pos.x * 0.08, screen.x + 40.0)
		if px < -20.0:
			px += screen.x + 40.0
		var py: float = fmod(s.y - cam_pos.y * 0.05, screen.y)
		var tw: float = 0.3 + 0.7 * absf(sin(t * 1.5 + s.x))
		draw_circle(Vector2(px, py), 1.5, Color(0.8, 0.9, 1.0, 0.4 * tw))

