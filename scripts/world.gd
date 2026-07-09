extends Node2D

# Holds the current room: solid platforms (with real collision), the exit door,
# and transient hit particles. Draws everything with a clean neon-tech look.

var platforms: Array = []            # Array[Rect2]
var door: Rect2 = Rect2(-999, -999, 0, 0)
var door_open: bool = false
var particles: Array = []            # {pos, vel, t, life, col, r}
var edge_col: Color = Color(0.25, 0.95, 0.85)
var t: float = 0.0
var bodies: Array = []

func build(level: Dictionary, ec: Color) -> void:
	clear()
	edge_col = ec
	platforms = level["platforms"].duplicate()
	for r in platforms:
		var body := StaticBody2D.new()
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		col.shape = shape
		col.position = r.position + r.size * 0.5
		body.add_child(col)
		add_child(body)
		bodies.append(body)
	var ex = level["exit"]
	if ex.x > -900:
		door = Rect2(ex.x, ex.y - 96.0, 52.0, 96.0)
	else:
		door = Rect2(-999, -999, 0, 0)
	door_open = false

func clear() -> void:
	for b in bodies:
		if is_instance_valid(b):
			b.queue_free()
	bodies.clear()
	platforms.clear()
	particles.clear()
	door_open = false

func add_burst(pos: Vector2, col: Color, n: int = 8) -> void:
	for i in range(n):
		var a: float = randf() * TAU
		var sp: float = 60.0 + randf() * 160.0
		particles.append({
			"pos": pos,
			"vel": Vector2(cos(a), sin(a)) * sp,
			"t": 0.0,
			"life": 0.3 + randf() * 0.3,
			"col": col,
			"r": 2.0 + randf() * 2.5,
		})

func _process(delta: float) -> void:
	t += delta
	for p in particles.duplicate():
		p["t"] += delta
		if p["t"] >= p["life"]:
			particles.erase(p)
			continue
		p["pos"] += p["vel"] * delta
		p["vel"] = p["vel"] * (1.0 - delta * 3.0)
		p["vel"].y += 200.0 * delta
	queue_redraw()

func point_solid(pt: Vector2) -> bool:
	for r in platforms:
		if r.has_point(pt):
			return true
	return false

func _draw() -> void:
	for r in platforms:
		_draw_platform(r)
	if door.size.x > 0:
		_draw_door()
	for p in particles:
		var f: float = 1.0 - p["t"] / p["life"]
		var c: Color = p["col"]
		draw_circle(p["pos"], p["r"] * f, Color(c.r, c.g, c.b, f))

func _draw_platform(r: Rect2) -> void:
	# body with subtle vertical gradient (two stacked rects)
	draw_rect(Rect2(r.position, r.size), Color(0.13, 0.15, 0.21))
	draw_rect(Rect2(r.position + Vector2(0, r.size.y * 0.5), Vector2(r.size.x, r.size.y * 0.5)), Color(0.09, 0.10, 0.15))
	# neon top edge
	var glow: float = 0.6 + 0.4 * sin(t * 2.0 + r.position.x * 0.02)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 3.0)), Color(edge_col.r, edge_col.g, edge_col.b, glow))
	draw_line(r.position + Vector2(0, -2), r.position + Vector2(r.size.x, -2), Color(edge_col.r, edge_col.g, edge_col.b, 0.2 * glow), 4.0)
	# rivets / tech dashes along the body
	var dx: float = 24.0
	var xx: float = r.position.x + 12.0
	while xx < r.position.x + r.size.x - 6.0:
		draw_rect(Rect2(xx, r.position.y + r.size.y - 6.0, 8.0, 2.0), Color(edge_col.r, edge_col.g, edge_col.b, 0.15))
		xx += dx

func _draw_door() -> void:
	var base: Color = Color(0.5, 0.5, 0.6)
	if door_open:
		base = Color(0.3, 1.0, 0.6)
	# frame
	draw_rect(door, Color(0.06, 0.07, 0.10))
	draw_rect(Rect2(door.position, Vector2(door.size.x, 4)), base)
	draw_rect(Rect2(door.position + Vector2(0, door.size.y - 4), Vector2(door.size.x, 4)), base)
	draw_rect(Rect2(door.position, Vector2(4, door.size.y)), base)
	draw_rect(Rect2(door.position + Vector2(door.size.x - 4, 0), Vector2(4, door.size.y)), base)
	# glowing core
	var pulse: float = 0.5 + 0.5 * sin(t * 3.0)
	var cx: float = door.position.x + door.size.x * 0.5
	for i in range(5):
		var yy: float = door.position.y + 14.0 + i * (door.size.y - 28.0) / 4.0
		draw_circle(Vector2(cx, yy), 4.0, Color(base.r, base.g, base.b, 0.4 + 0.5 * pulse))
	if door_open:
		draw_arc(Vector2(cx, door.position.y + door.size.y * 0.5), 40.0, 0, TAU, 32, Color(base.r, base.g, base.b, 0.25 * pulse), 3.0)
