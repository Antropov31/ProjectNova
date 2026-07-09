extends RefCounted
class_name CutScenes

# Presentation code pulled out of game.gd. All draws are issued on the passed-in
# game node `g` during its own _draw() cycle, so g.draw_* is valid here.

# The imported CompressedTexture2D sometimes fails to resolve at runtime and
# draws as a white rectangle. We sidestep the import system entirely by loading
# the raw PNG into an Image once and caching an ImageTexture.
static var _logo_tex: Texture2D = null
static var _logo_tried: bool = false

static func get_logo() -> Texture2D:
	if _logo_tried:
		return _logo_tex
	_logo_tried = true
	var img: Image = Image.new()
	var p: String = ProjectSettings.globalize_path("res://logo.png")
	var err: int = img.load(p)
	if err != OK:
		err = img.load("res://logo.png")
	if err == OK:
		_logo_tex = ImageTexture.create_from_image(img)
	return _logo_tex

# Draw a string horizontally centered on cx.
static func ctext(g, s: String, cx: float, y: float, size: int, col: Color) -> void:
	var w: float = g.font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var ox: float = cx - w * 0.5
	# dark outline for legibility on any background
	var oc := Color(0.0, 0.0, 0.02, col.a * 0.9)
	for d in [Vector2(-1,0), Vector2(1,0), Vector2(0,-1), Vector2(0,1)]:
		g.draw_string(g.font, Vector2(ox + d.x, y + d.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, oc)
	g.draw_string(g.font, Vector2(ox, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

static func boot_engine(g) -> void:
	var W: float = g.COLS * g.TILE; var H: float = g.ROWS * g.TILE
	g.draw_rect(Rect2(0,0,W,H), Color(0.18,0.20,0.24))
	var a: float = clamp(sin(g.boot_t / 2.3 * PI), 0.0, 1.0)
	var cx: float = W*0.5; var cy: float = H*0.42
	var blue := Color(0.26,0.54,0.79, a)
	g.draw_rect(Rect2(cx-20, cy-16, 40, 30), blue)
	g.draw_rect(Rect2(cx-24, cy-8, 48, 20), blue)
	for i in range(5):
		g.draw_rect(Rect2(cx - 20 + i*10, cy-22, 6, 8), blue)
	g.draw_circle(Vector2(cx-9, cy-2), 5, Color(1,1,1,a))
	g.draw_circle(Vector2(cx+9, cy-2), 5, Color(1,1,1,a))
	g.draw_circle(Vector2(cx-9, cy-2), 2.4, Color(0.2,0.22,0.26,a))
	g.draw_circle(Vector2(cx+9, cy-2), 2.4, Color(0.2,0.22,0.26,a))
	g.draw_rect(Rect2(cx-1, cy-4, 2, 6), Color(1,1,1,a))
	ctext(g, "сделано на Godot Engine", cx, cy+34, 8, Color(0.8,0.85,0.9,a))
	_skip_hint(g)

static func boot_logo(g) -> void:
	var W: float = g.COLS * g.TILE; var H: float = g.ROWS * g.TILE
	var a: float = clamp(sin(g.boot_t / 2.4 * PI), 0.0, 1.0)
	g.draw_rect(Rect2(0,0,W,H), Color(0.04,0.05,0.07))
	var tex: Texture2D = get_logo()
	if tex != null:
		var iw: float = 150.0
		var ih: float = iw * float(tex.get_height()) / float(max(1, tex.get_width()))
		if ih > H - 30.0:
			ih = H - 30.0
			iw = ih * float(tex.get_width()) / float(max(1, tex.get_height()))
		# soft glow behind the mark
		g.draw_circle(Vector2(W*0.5, (H-ih)*0.5 - 6 + ih*0.5), iw*0.5, Color(0.3,0.6,0.9,0.08*a))
		g.draw_texture_rect(tex, Rect2((W-iw)*0.5, (H-ih)*0.5 - 8, iw, ih), false, Color(1,1,1,a))
		ctext(g, "представляет", W*0.5, H-12, 7, Color(0.6,0.65,0.72,a))
		_skip_hint(g)
		return
	# Fallback: procedural GLITCHCAT emblem.
	var cx: float = W*0.5; var cy: float = H*0.40
	g.draw_colored_polygon(PackedVector2Array([Vector2(cx-18,cy-10),Vector2(cx-12,cy-24),Vector2(cx-4,cy-12)]), Color(0.08,0.08,0.10,a))
	g.draw_colored_polygon(PackedVector2Array([Vector2(cx-15,cy-12),Vector2(cx-12,cy-20),Vector2(cx-8,cy-13)]), Color(0.85,0.25,0.35,a))
	g.draw_colored_polygon(PackedVector2Array([Vector2(cx+18,cy-10),Vector2(cx+12,cy-24),Vector2(cx+4,cy-12)]), Color(0.9,0.9,0.93,a))
	g.draw_colored_polygon(PackedVector2Array([Vector2(cx+15,cy-12),Vector2(cx+12,cy-20),Vector2(cx+8,cy-13)]), Color(0.85,0.25,0.35,a))
	g.draw_rect(Rect2(cx-16, cy-12, 16, 26), Color(0.10,0.10,0.12,a))
	g.draw_rect(Rect2(cx, cy-12, 16, 26), Color(0.88,0.88,0.91,a))
	g.draw_circle(Vector2(cx-8, cy-2), 2.5, Color(0.9,0.9,0.9,a))
	g.draw_circle(Vector2(cx+8, cy-2), 2.5, Color(0.1,0.1,0.12,a))
	ctext(g, "G L I T C H C A T", cx, cy+34, 11, Color(0.85,0.88,0.92,a))
	ctext(g, "представляет", cx, cy+46, 7, Color(0.6,0.65,0.72,a))
	_skip_hint(g)

static func _skip_hint(g) -> void:
	var W: float = g.COLS * g.TILE; var H: float = g.ROWS * g.TILE
	if int(g.menu_t*2.0) % 2 == 0:
		g.draw_string(g.font, Vector2(W-70, H-6), "КОСНИСЬ, ЧТОБЫ ПРОПУСТИТЬ", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.5,0.55,0.6))

# ---- shared main-computer sprite (identical in intro and boss fight) --------

static func draw_computer_frame(g, cx: float, cy: float, r: float, screen: Color, bez: Color) -> void:
	# base stand
	g.draw_rect(Rect2(cx - 8.0, cy + r + 2.0, 16.0, 8.0), bez.darkened(0.2))
	g.draw_rect(Rect2(cx - 16.0, cy + r + 9.0, 32.0, 3.0), bez.darkened(0.35))
	# bezel
	g.draw_rect(Rect2(cx - r - 4, cy - r - 4, r*2 + 8, r*2 + 8), bez)
	g.draw_rect(Rect2(cx - r - 4, cy - r - 4, r*2 + 8, 2), bez.lightened(0.25))
	# screen
	g.draw_rect(Rect2(cx - r, cy - r, r*2, r*2), screen)
	var sy: float = cy - r
	while sy < cy + r:
		g.draw_rect(Rect2(cx - r, sy, r*2, 1), Color(0, 0, 0, 0.12))
		sy += 3.0

static func draw_computer_good(g, cx: float, cy: float, r: float, t: float, a: float = 1.0) -> void:
	draw_computer_frame(g, cx, cy, r, Color(0.08, 0.30, 0.50, a), Color(0.14, 0.16, 0.22, a))
	var glow := Color(0.5, 1.0, 1.0, a)
	var blink: bool = int(t * 1.3) % 6 == 0
	var eh: float = 1.0 if blink else r * 0.28
	g.draw_rect(Rect2(cx - r*0.5, cy - r*0.32, r*0.28, eh), glow)
	g.draw_rect(Rect2(cx + r*0.22, cy - r*0.32, r*0.28, eh), glow)
	# warm smile arc
	var teeth := 7
	for i in range(teeth):
		var mx: float = cx - r*0.5 + (r) * float(i)/float(teeth-1)
		var my: float = cy + r*0.28 + sin(float(i)/float(teeth-1) * PI) * r*0.22
		g.draw_rect(Rect2(mx, my, r*0.12, r*0.12), glow)
	g.draw_circle(Vector2(cx - r*0.7, cy + r*0.15), r*0.12, Color(0.4, 0.85, 1.0, a*0.4))
	g.draw_circle(Vector2(cx + r*0.7, cy + r*0.15), r*0.12, Color(0.4, 0.85, 1.0, a*0.4))

static func draw_computer_virus(g, cx: float, cy: float, r: float, t: float, a: float = 1.0, eye_target: Vector2 = Vector2.ZERO) -> void:
	# red aura
	var pulse: float = 0.5 + 0.5 * sin(t * 6.0)
	g.draw_circle(Vector2(cx, cy), r + 6.0 + pulse * 4.0, Color(1.0, 0.1, 0.12, 0.14 * a))
	draw_computer_frame(g, cx, cy, r, Color(0.12, 0.02, 0.03, a), Color(0.14, 0.05, 0.06, a))
	# green data streams
	for ci in range(6):
		var colx: float = cx - r + 3.0 + ci * (r * 2.0 / 6.0)
		var stream: float = fmod(t * 26.0 + ci * 13.0, r * 2.0)
		for cj in range(4):
			var cyy: float = cy - r + fmod(stream + cj * 5.0, r * 2.0)
			var gg: float = 0.4 + 0.6 * float((int(t * 8.0) + ci + cj) % 2)
			g.draw_rect(Rect2(colx, cyy, 2, 3), Color(0.3, 1.0, 0.4, 0.35 * gg * a))
	if int(t*10.0) % 4 == 0:
		g.draw_rect(Rect2(cx - r, cy + randf_range(-r, r), r*2, 2), Color(1.0, 0.3, 0.4, 0.4 * a))
	# evil red face
	var red := Color(1.0, 0.25, 0.2, a)
	var eo: float = clamp(eye_target.x * 0.05, -3.0, 3.0) if eye_target != Vector2.ZERO else 2.0 * sin(t * 1.5)
	g.draw_colored_polygon(PackedVector2Array([
		Vector2(cx-r*0.6, cy-r*0.4), Vector2(cx-r*0.1, cy-r*0.2),
		Vector2(cx-r*0.1, cy+r*0.05), Vector2(cx-r*0.6, cy-r*0.05)]), red)
	g.draw_colored_polygon(PackedVector2Array([
		Vector2(cx+r*0.6, cy-r*0.4), Vector2(cx+r*0.1, cy-r*0.2),
		Vector2(cx+r*0.1, cy+r*0.05), Vector2(cx+r*0.6, cy-r*0.05)]), red)
	g.draw_circle(Vector2(cx-r*0.35+eo, cy-r*0.15), r*0.1, Color(1.0, 0.9, 0.5, a))
	g.draw_circle(Vector2(cx+r*0.35+eo, cy-r*0.15), r*0.1, Color(1.0, 0.9, 0.5, a))
	var my: float = cy + r * 0.35
	var mh: float = 4.0 + (0.5 + 0.5 * sin(t*3.0)) * 6.0
	var pts := PackedVector2Array()
	var teeth := 6
	for i in range(teeth + 1):
		var mx: float = cx - r*0.6 + (r*1.2) * float(i)/teeth
		pts.append(Vector2(mx, my + (0.0 if i % 2 == 0 else mh)))
	for i in range(teeth, -1, -1):
		var mx2: float = cx - r*0.6 + (r*1.2) * float(i)/teeth
		pts.append(Vector2(mx2, my + mh + (mh if i % 2 == 0 else 0.0)))
	g.draw_colored_polygon(pts, red)

# Friendly companion robot Nova, rendered as detailed pixel art with a gentle hover.
static func draw_nova(g, cx: float, cy: float, t: float) -> void:
	var bob: float = sin(t * 1.4) * 3.0
	var yy: float = cy + bob
	var pulse: float = 0.5 + 0.5 * sin(t * 2.2)
	# layered halo
	g.draw_circle(Vector2(cx, yy), 40.0 + pulse * 5.0, Color(0.3, 0.85, 1.0, 0.06))
	g.draw_circle(Vector2(cx, yy), 28.0, Color(0.35, 0.9, 1.0, 0.10))
	# ground shadow (grounded, does not bob)
	g.draw_circle(Vector2(cx, cy + 30.0), 15.0, Color(0, 0, 0, 0.22))
	# hover thruster plume
	var th: float = 6.0 + (0.5 + 0.5 * sin(t * 10.0)) * 5.0
	g.draw_colored_polygon(PackedVector2Array([Vector2(cx - 5, yy + 20), Vector2(cx + 5, yy + 20), Vector2(cx, yy + 20 + th)]), Color(0.5, 0.95, 1.0, 0.55))
	g.draw_colored_polygon(PackedVector2Array([Vector2(cx - 2.5, yy + 20), Vector2(cx + 2.5, yy + 20), Vector2(cx, yy + 20 + th * 0.6)]), Color(0.85, 1.0, 1.0, 0.8))
	# side fins
	var fin: float = sin(t * 2.0) * 2.0
	g.draw_colored_polygon(PackedVector2Array([Vector2(cx - 17, yy - 4 + fin), Vector2(cx - 11, yy - 2), Vector2(cx - 11, yy + 8), Vector2(cx - 18, yy + 6 + fin)]), Color(0.18, 0.62, 0.72))
	g.draw_colored_polygon(PackedVector2Array([Vector2(cx + 17, yy - 4 - fin), Vector2(cx + 11, yy - 2), Vector2(cx + 11, yy + 8), Vector2(cx + 18, yy + 6 - fin)]), Color(0.18, 0.62, 0.72))
	g.draw_circle(Vector2(cx - 15, yy + 2 + fin), 2.0, Color(0.5, 1.0, 1.0))
	g.draw_circle(Vector2(cx + 15, yy + 2 - fin), 2.0, Color(0.5, 1.0, 1.0))
	# rounded body shell (teal, plated, glossy top)
	g.draw_circle(Vector2(cx, yy + 4), 16.0, Color(0.10, 0.20, 0.28))
	g.draw_circle(Vector2(cx, yy + 3), 15.0, Color(0.16, 0.66, 0.74))
	g.draw_circle(Vector2(cx, yy - 1), 13.0, Color(0.22, 0.78, 0.86))
	g.draw_circle(Vector2(cx - 4, yy - 5), 5.0, Color(0.7, 0.98, 1.0, 0.5))
	# plating seams
	g.draw_line(Vector2(cx - 13, yy + 6), Vector2(cx + 13, yy + 6), Color(0.08, 0.32, 0.4, 0.7), 1.0)
	g.draw_line(Vector2(cx - 10, yy + 10), Vector2(cx + 10, yy + 10), Color(0.08, 0.32, 0.4, 0.5), 1.0)
	# face visor
	g.draw_rect(Rect2(cx - 11, yy - 6, 22, 11), Color(0.04, 0.10, 0.16))
	g.draw_rect(Rect2(cx - 11, yy - 6, 22, 2), Color(0.2, 0.5, 0.6, 0.6))
	# one big expressive eye that tracks a slow arc
	var look := Vector2(sin(t * 0.8) * 3.0, cos(t * 1.1) * 1.5)
	var ecol := Color(0.45, 1.0, 0.95)
	g.draw_circle(Vector2(cx, yy - 0.5) + look, 5.0, Color(ecol.r, ecol.g, ecol.b, 0.35))
	g.draw_circle(Vector2(cx, yy - 0.5) + look, 3.4, ecol)
	g.draw_circle(Vector2(cx, yy - 0.5) + look, 1.6, Color(1, 1, 1))
	# blink
	if int(t * 1.3) % 7 == 0:
		g.draw_rect(Rect2(cx - 6, yy - 1.5, 12, 3), Color(0.04, 0.10, 0.16))
	# chest core light
	g.draw_circle(Vector2(cx, yy + 9), 2.6, Color(0.4, 1.0, 1.0, 0.5 + 0.5 * pulse))
	g.draw_circle(Vector2(cx, yy + 9), 1.2, Color(1, 1, 1, 0.8 * pulse))
	# antenna with blinking tip
	g.draw_line(Vector2(cx, yy - 13), Vector2(cx + 2, yy - 22), Color(0.6, 0.8, 0.88), 1.5)
	var blink: float = 0.4 + 0.6 * abs(sin(t * 3.0))
	g.draw_circle(Vector2(cx + 2, yy - 22), 2.2, Color(1.0, 0.45, 0.5, blink))
	g.draw_circle(Vector2(cx + 2, yy - 22), 1.0, Color(1, 1, 1, blink))

static func _menu_factory(g, W: float, H: float) -> void:
	var t: float = g.menu_t
	# far skyline of the infected complex
	var bx: float = 0.0
	var bi: int = 0
	while bx < W:
		var bw: float = 22.0 + float((bi * 37) % 26)
		var bh: float = 26.0 + float((bi * 53) % 46)
		var by: float = H * 0.62 - bh
		g.draw_rect(Rect2(bx, by, bw - 3.0, bh), Color(0.05, 0.06, 0.11, 0.85))
		g.draw_rect(Rect2(bx, by, bw - 3.0, 1.0), Color(0.12, 0.16, 0.24, 0.7))
		# a few flickering windows, most dead
		for wy in range(int(bh / 8.0)):
			for wx in range(int((bw - 6.0) / 7.0)):
				var seed: int = bi * 91 + wy * 13 + wx * 7
				if seed % 5 == 0:
					var fl: float = 0.15 + 0.35 * (0.5 + 0.5 * sin(t * 2.0 + seed))
					var wc := Color(0.9, 0.4, 0.2, fl) if seed % 3 == 0 else Color(0.3, 0.5, 0.7, fl * 0.6)
					g.draw_rect(Rect2(bx + 3.0 + wx * 7.0, by + 3.0 + wy * 8.0, 3.0, 4.0), wc)
		bx += bw
		bi += 1
	# the core: a red wound of light low-centre, pulsing
	var pulse: float = 0.5 + 0.5 * sin(t * 1.6)
	var ccx: float = W * 0.5
	var ccy: float = H * 0.6
	g.draw_circle(Vector2(ccx, ccy), 60.0 + pulse * 14.0, Color(0.6, 0.05, 0.1, 0.05 + 0.05 * pulse))
	g.draw_circle(Vector2(ccx, ccy), 30.0 + pulse * 8.0, Color(0.9, 0.1, 0.15, 0.06 + 0.06 * pulse))
	# embers / drifting sparks rising from the core
	for i in range(14):
		var sp: float = fmod(t * (10.0 + i) + i * 33.0, 90.0)
		var ex: float = ccx + sin(t * 0.6 + i) * (30.0 + i * 3.0)
		var ey: float = ccy - sp
		var ea: float = clamp(1.0 - sp / 90.0, 0.0, 1.0) * 0.6
		g.draw_rect(Rect2(ex, ey, 1.5, 1.5), Color(1.0, 0.55, 0.25, ea))
	# slow drifting smoke bands
	for s in range(3):
		var smy: float = H * 0.30 + s * 10.0 + sin(t * 0.4 + s) * 4.0
		var smx: float = fmod(t * (6.0 + s * 2.0), W + 60.0) - 30.0
		g.draw_circle(Vector2(smx, smy), 14.0 - s * 2.0, Color(0.1, 0.05, 0.08, 0.06))

static func menu(g) -> void:
	var W: float = g.COLS * g.TILE; var H: float = g.ROWS * g.TILE
	# deep gradient sky
	g.draw_rect(Rect2(0,0,W,H), Color(0.03,0.04,0.08))
	g.draw_rect(Rect2(0,0,W,H*0.5), Color(0.05,0.07,0.13,0.6))
	_menu_factory(g, W, H)
	# scrolling grid floor lines
	var off: float = fmod(g.bg_scroll, 32.0)
	var x: float = -32.0 + off
	while x < W:
		g.draw_line(Vector2(x,0), Vector2(x,H), Color(0.10,0.14,0.20), 1.0)
		x += 32.0
	# stars
	for i in range(20):
		var sx: float = fmod(i*53.0 + g.bg_scroll*2.0, W)
		var sy: float = fmod(i*37.0 + g.bg_scroll, H)
		var tw: float = 0.4 + 0.4*sin(g.menu_t*2.0 + i)
		g.draw_circle(Vector2(sx,sy), 1.0, Color(0.4,0.8,0.9,tw))
	for i in range(16):
		var dpx: float = fmod(i * 71.0 - g.bg_scroll * 3.0 + W, W)
		var dpy: float = fmod(i * 43.0 + g.menu_t * 14.0, H)
		var dpa: float = 0.12 + 0.22 * sin(g.menu_t * 1.5 + i)
		g.draw_rect(Rect2(dpx, dpy, 1.0, 3.0), Color(0.35, 0.85, 1.0, dpa))
	# Nova art centerpiece with a soft halo
	var ncx: float = W*0.5; var ncy: float = H*0.36
	g.draw_circle(Vector2(ncx, ncy+2), 34.0 + sin(g.menu_t*2.0)*3.0, Color(0.25,0.7,0.95,0.07))
	draw_nova(g, ncx, ncy, g.menu_t)
	# Title, centered, with occasional glitch echo
	var ty: float = H*0.72
	for gi in range(6):
		ctext(g, "PROJECT NOVA", ncx, ty, 20, Color(0.3, 0.8, 1.0, 0.05))
	var jit: float = (randf_range(-1.5, 1.5) if int(g.menu_t * 3.0) % 11 == 0 else 0.0)
	ctext(g, "PROJECT NOVA", ncx - 1.5 + jit, ty, 20, Color(1.0, 0.25, 0.4, 0.45))
	ctext(g, "PROJECT NOVA", ncx + 1.5, ty, 20, Color(0.2, 0.7, 1.0, 0.45))
	ctext(g, "PROJECT NOVA", ncx, ty, 20, Color(0.78, 0.98, 1.0))
	ctext(g, g.T("Топ-даун экшн. Пробейся к ядру завода.", "Top-down action. Fight to the core."), ncx, ty+13, 8, Color(0.55,0.72,0.82))
	# Menu options, centered
	var opulse: float = 0.7 + 0.3*sin(g.menu_t*4.0)
	# soft framed panel behind the call-to-action buttons
	var panel_y: float = H - 46.0
	g.draw_rect(Rect2(ncx - 96, panel_y, 192, 40), Color(0.04, 0.06, 0.11, 0.55))
	g.draw_rect(Rect2(ncx - 96, panel_y, 192, 1), Color(0.3, 0.7, 1.0, 0.5))
	g.draw_rect(Rect2(ncx - 96, panel_y + 39, 192, 1), Color(0.3, 0.7, 1.0, 0.25))
	if g.has_save:
		ctext(g, g.T("КОСНИСЬ  -  новая игра", "SPACE  -  new game"), ncx, H-34, 9, Color(0.78,0.97,1.0,opulse))
		ctext(g, g.T("C  -  продолжить", "C  -  continue"), ncx, H-23, 8, Color(0.6,0.9,0.72))
	else:
		ctext(g, g.T("КОСНИСЬ  -  начать игру", "SPACE  -  start"), ncx, H-30, 10, Color(0.78,0.97,1.0,opulse))
	ctext(g, g.T("левый стик: ходьба   правый стик: огонь", "WASD move   mouse aim   J fire"), ncx, H-14, 8, Color(0.52,0.62,0.72))
	ctext(g, g.T("экранные кнопки: рывок, оружие, Nova, предметы", "Shift dash   Q weapon   F Nova   Esc pause"), ncx, H-6, 8, Color(0.52,0.62,0.72))
	var dyy: float = H * 0.60
	var dlabels: Array = ["1 ЛЁГКО", "2 НОРМА", "3 ХАРД"]
	var dws: Array = []
	var dtot: float = 0.0
	for dl in dlabels:
		var dw: float = g.font.get_string_size(dl, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		dws.append(dw); dtot += dw + 8.0
	var dx0: float = ncx - dtot * 0.5
	for di in range(3):
		var dsel: bool = g.difficulty == di
		if dsel:
			g.draw_rect(Rect2(dx0 - 3.0, dyy - 8.0, float(dws[di]) + 6.0, 11.0), Color(0.2, 0.5, 0.35, 0.55))
		g.draw_string(g.font, Vector2(dx0, dyy), dlabels[di], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, (Color(0.95, 1.0, 0.75) if dsel else Color(0.5, 0.6, 0.68)))
		dx0 += float(dws[di]) + 8.0
	if g.ng_plus > 0:
		g.draw_string(g.font, Vector2(W - 42.0, 14.0), "NG+" + str(g.ng_plus), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.6, 0.3))
	# Studio logo, small in the bottom-left corner
	var tex: Texture2D = get_logo()
	if tex != null:
		var lw: float = 26.0
		var lh: float = lw * float(tex.get_height()) / float(max(1, tex.get_width()))
		g.draw_texture_rect(tex, Rect2(6, H-6-lh, lw, lh), false, Color(1,1,1,0.85))
	else:
		g.draw_string(g.font, Vector2(6, H-8), "GLITCHCAT", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.5,0.55,0.62))
	g.draw_string(g.font, Vector2(W - 78.0, H - 20.0), g.T("L - язык: РУ", "L - lang: EN"), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.55, 0.72, 0.82))
	_crt(g, W, H)

# ---- intro cinematic (crafted pixel-art) -----------------------------------

static func intro(g) -> void:
	var W: float = g.COLS * g.TILE
	var H: float = g.ROWS * g.TILE
	var local_t: float = g.cut_t
	var fade_in: float = clamp(local_t / 0.55, 0.0, 1.0)
	var fade_out: float = clamp((4.5 - local_t) / 0.55, 0.0, 1.0)
	var fade: float = fade_in * fade_out
	g.draw_rect(Rect2(0, 0, W, H), Color(0.025, 0.035, 0.055))
	# slow cinematic push and lateral drift, reset before UI overlays
	var z: float = 1.0 + clamp(local_t / 4.5, 0.0, 1.0) * 0.025
	var drift := Vector2(-W * (z - 1.0) * 0.5 + sin(local_t * 0.7) * 1.5, -H * (z - 1.0) * 0.5)
	g.draw_set_transform(drift, 0.0, Vector2(z, z))
	match g.cut_phase:
		0: _scene_complex(g, W, H, fade)
		1: _scene_computer(g, W, H, fade)
		2: _scene_attack(g, W, H, fade)
		_: _scene_hero(g, W, H, fade)
	g.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# flash-frame at the infection and attack cuts
	if (g.cut_phase == 1 and local_t > 2.15 and local_t < 2.27) or (g.cut_phase == 2 and local_t < 0.16):
		g.draw_rect(Rect2(0,0,W,H), Color(0.75,0.9,1.0,0.20))
	# cinematic bars, chapter slug and timeline
	g.draw_rect(Rect2(0, 0, W, 11), Color(0.01, 0.015, 0.025, 0.98))
	g.draw_rect(Rect2(0, H - 11, W, 11), Color(0.01, 0.015, 0.025, 0.98))
	var slugs: Array = ["01  НОЧНАЯ СМЕНА", "02  НУЛЕВОЙ ПАЦИЕНТ", "03  ПРОТОКОЛ КРАСНЫЙ", "04  ПОСЛЕДНИЙ ИНЖЕНЕР"]
	g.draw_string(g.font, Vector2(7, 8), slugs[g.cut_phase], HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.55,0.75,0.86))
	for di in range(4):
		var active: bool = di == g.cut_phase
		var dc := Color(0.55, 0.92, 1.0, 0.95) if active else Color(0.25, 0.34, 0.42, 0.7)
		var ww: float = 13.0 if active else 5.0
		g.draw_rect(Rect2(W * 0.5 - 22 + di * 14, 4, ww, 2), dc)
	if int(g.menu_t * 2.0) % 2 == 0:
		g.draw_string(g.font, Vector2(W - 80, H - 4), "КОСНИСЬ, ЧТОБЫ ПРОПУСТИТЬ", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.5,0.6,0.68))
	# true fade to black between scenes
	var black: float = 1.0 - min(fade_in, fade_out)
	if black > 0.01:
		g.draw_rect(Rect2(0,0,W,H), Color(0.01,0.015,0.025,black))

static func _cap(g, s: String, a: float, col: Color) -> void:
	var W: float = g.COLS * g.TILE
	g.draw_rect(Rect2(0, 10, W, 12), Color(0.02, 0.03, 0.05, 0.55 * a))
	g.draw_string(g.font, Vector2(6, 19), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(col.r, col.g, col.b, a))

static func _ground(g, W: float, H: float, a: float) -> void:
	g.draw_rect(Rect2(0, H * 0.70, W, H * 0.30), Color(0.09, 0.10, 0.13, a))
	g.draw_rect(Rect2(0, H * 0.70, W, 1), Color(0.22, 0.26, 0.34, a))
	for i in range(8):
		var lx: float = float(i) * (W / 8.0)
		g.draw_line(Vector2(lx, H * 0.70), Vector2(lx - 6.0, H), Color(0.13, 0.15, 0.20, a * 0.6), 1.0)

# ---- reusable sprites -------------------------------------------------------

static func _person(g, x: float, y: float, a: float, shirt: Color, facing: int, walk: float, panic: bool = false) -> void:
	var skin := Color(0.94, 0.78, 0.63, a)
	var skin_dk := Color(0.78, 0.62, 0.48, a)
	var hair := Color(0.22, 0.15, 0.10, a)
	var step: float = sin(walk) * 2.4
	g.draw_circle(Vector2(x, y + 1.0), 5.8, Color(0, 0, 0, 0.30 * a))
	# legs with knee shading
	g.draw_rect(Rect2(x - 3.2, y - 6.0, 2.8, 6.0 + step), Color(0.18, 0.20, 0.28, a))
	g.draw_rect(Rect2(x + 0.6, y - 6.0, 2.8, 6.0 - step), Color(0.22, 0.24, 0.32, a))
	g.draw_rect(Rect2(x - 3.2, y - 1.0 + step, 2.8, 1.5), Color(0.10, 0.10, 0.14, a))
	g.draw_rect(Rect2(x + 0.6, y - 1.0 - step, 2.8, 1.5), Color(0.10, 0.10, 0.14, a))
	# torso shirt with shading + collar
	g.draw_rect(Rect2(x - 3.8, y - 13.0, 7.6, 8.0), shirt)
	g.draw_rect(Rect2(x - 3.8, y - 13.0, 7.6, 2.0), shirt.lightened(0.22))
	g.draw_rect(Rect2(x + 1.6, y - 13.0, 2.2, 8.0), shirt.darkened(0.18))
	g.draw_rect(Rect2(x - 1.2, y - 13.0, 2.4, 2.0), Color(0.9,0.9,0.92,a*0.7))
	# arms react to panic
	var arm_up: float = -4.0 if panic else 0.0
	g.draw_rect(Rect2(x - 5.2, y - 12.0 + arm_up, 1.9, 6.5), skin_dk)
	g.draw_rect(Rect2(x + 3.3, y - 12.0 + arm_up, 1.9, 6.5), skin)
	# head with hair + ear
	g.draw_circle(Vector2(x, y - 15.6), 3.4, skin)
	g.draw_circle(Vector2(x - facing*3.2, y - 15.6), 0.8, skin_dk)
	g.draw_rect(Rect2(x - 3.4, y - 19.0, 6.8, 2.6), hair)
	g.draw_rect(Rect2(x - 3.4, y - 17.2, 1.2, 2.0), hair)
	# face
	var ex: float = facing * 1.0
	if panic:
		g.draw_circle(Vector2(x + ex, y - 15.0), 1.0, Color(0.1, 0.05, 0.05, a))
		g.draw_rect(Rect2(x - 1.0 + ex, y - 13.2, 2.0, 1.2), Color(0.4,0.1,0.1,a))
	else:
		g.draw_rect(Rect2(x - 1.5 + ex, y - 16.0, 1.0, 1.0), Color(0.1, 0.1, 0.12, a))
		g.draw_rect(Rect2(x + 0.5 + ex, y - 16.0, 1.0, 1.0), Color(0.1, 0.1, 0.12, a))

static func _robot(g, x: float, y: float, a: float, evil: bool, t: float, hover: float = 0.0) -> void:
	var yy: float = y + sin(t * 2.0 + x) * hover
	var body := Color(0.30, 0.62, 0.85, a) if not evil else Color(0.55, 0.14, 0.15, a)
	var trim := Color(0.5, 0.85, 1.0, a) if not evil else Color(1.0, 0.3, 0.25, a)
	var eye := Color(0.5, 1.0, 0.95, a) if not evil else Color(1.0, 0.25, 0.2, a)
	g.draw_circle(Vector2(x, y + 1.0), 6.0, Color(0, 0, 0, 0.25 * a))
	g.draw_rect(Rect2(x - 5.0, yy - 4.0, 3.0, 8.0), body.darkened(0.3))
	g.draw_rect(Rect2(x + 2.0, yy - 4.0, 3.0, 8.0), body.darkened(0.3))
	g.draw_rect(Rect2(x - 6.0, yy - 14.0, 12.0, 12.0), body)
	g.draw_rect(Rect2(x - 6.0, yy - 14.0, 12.0, 3.0), trim)
	g.draw_rect(Rect2(x - 6.0, yy - 3.0, 12.0, 1.0), body.darkened(0.4))
	if evil:
		g.draw_rect(Rect2(x - 10.0, yy - 15.0, 4.0, 2.0), body.darkened(0.2))
		g.draw_rect(Rect2(x + 6.0, yy - 15.0, 4.0, 2.0), body.darkened(0.2))
		g.draw_rect(Rect2(x - 11.0, yy - 17.0, 2.0, 3.0), trim)
		g.draw_rect(Rect2(x + 9.0, yy - 17.0, 2.0, 3.0), trim)
	else:
		g.draw_rect(Rect2(x - 8.0, yy - 10.0, 2.5, 5.0), body.darkened(0.2))
		g.draw_rect(Rect2(x + 5.5, yy - 10.0, 2.5, 5.0), body.darkened(0.2))
	g.draw_rect(Rect2(x - 4.5, yy - 20.0, 9.0, 7.0), body.lightened(0.1))
	g.draw_rect(Rect2(x - 3.5, yy - 18.5, 7.0, 4.0), Color(0.05, 0.08, 0.12, a))
	if evil:
		g.draw_colored_polygon(PackedVector2Array([Vector2(x - 3.5, yy - 17.5), Vector2(x - 1.0, yy - 16.5), Vector2(x - 3.5, yy - 15.5)]), eye)
		g.draw_colored_polygon(PackedVector2Array([Vector2(x + 3.5, yy - 17.5), Vector2(x + 1.0, yy - 16.5), Vector2(x + 3.5, yy - 15.5)]), eye)
	else:
		g.draw_circle(Vector2(x - 2.0, yy - 16.5), 1.2, eye)
		g.draw_circle(Vector2(x + 2.0, yy - 16.5), 1.2, eye)
		g.draw_rect(Rect2(x - 2.0, yy - 14.0, 4.0, 0.8), eye)
	g.draw_rect(Rect2(x - 0.5, yy - 23.0, 1.0, 3.0), body.lightened(0.2))
	g.draw_circle(Vector2(x, yy - 23.5), 1.1, eye)

static func _desk(g, x: float, y: float, a: float, t: float) -> void:
	g.draw_rect(Rect2(x - 10.0, y - 8.0, 20.0, 4.0), Color(0.28, 0.24, 0.18, a))
	g.draw_rect(Rect2(x - 10.0, y - 8.0, 20.0, 1.0), Color(0.4, 0.34, 0.26, a))
	g.draw_rect(Rect2(x - 9.0, y - 4.0, 2.0, 4.0), Color(0.18, 0.15, 0.12, a))
	g.draw_rect(Rect2(x + 7.0, y - 4.0, 2.0, 4.0), Color(0.18, 0.15, 0.12, a))
	g.draw_rect(Rect2(x - 5.0, y - 16.0, 10.0, 7.0), Color(0.10, 0.12, 0.16, a))
	var fl: float = 0.7 + 0.3 * sin(t * 5.0 + x)
	g.draw_rect(Rect2(x - 4.0, y - 15.0, 8.0, 5.0), Color(0.25, 0.65, 0.9, a * fl))
	g.draw_rect(Rect2(x - 1.0, y - 9.0, 2.0, 1.0), Color(0.10, 0.12, 0.16, a))

# ---- phase 0: the company complex ------------------------------------------

static func _scene_complex(g, W: float, H: float, a: float) -> void:
	g.draw_rect(Rect2(0, 9, W, H * 0.70 - 9), Color(0.09, 0.11, 0.17, a))
	var seg: float = (W - 48.0) / 3.0
	for wi in range(3):
		var wx: float = 24.0 + wi * seg
		g.draw_rect(Rect2(wx, 20, seg - 14.0, H * 0.34), Color(0.05, 0.08, 0.16, a))
		g.draw_rect(Rect2(wx, 20, seg - 14.0, H * 0.34), Color(0.2, 0.4, 0.6, a * 0.4), false, 1.0)
		for li in range(6):
			var lx: float = wx + 3.0 + float((li * 7) % int(max(1.0, seg - 16.0)))
			var lh: float = 6.0 + float((li * 13) % 18)
			g.draw_rect(Rect2(lx, 20 + H * 0.34 - lh, 3.0, lh), Color(0.15, 0.2, 0.3, a))
			g.draw_rect(Rect2(lx, 20 + H * 0.34 - lh + 1.0, 1.0, 1.0), Color(0.9, 0.85, 0.5, a * 0.7))
	_cap(g, "«НОВА РОБОТИКС» - ночная смена. Люди и машины бок о бок.", a, Color(0.8, 0.92, 1.0))
	_ground(g, W, H, a)
	for di in range(3):
		_desk(g, W * 0.22 + di * W * 0.28, H * 0.70, a, g.menu_t)
	_person(g, W * 0.18, H * 0.70, a, Color(0.3, 0.5, 0.8, a), 1, g.menu_t * 2.0)
	_person(g, W * 0.50, H * 0.70, a, Color(0.7, 0.4, 0.4, a), -1, g.menu_t * 2.2 + 1.0)
	_person(g, W * 0.82, H * 0.70, a, Color(0.4, 0.6, 0.5, a), -1, g.menu_t * 1.8 + 2.0)
	_robot(g, W * 0.34, H * 0.70, a, false, g.menu_t, 2.0)
	_robot(g, W * 0.66, H * 0.70, a, false, g.menu_t + 1.5, 2.0)

# ---- phase 1: the good computer gets infected ------------------------------

static func _scene_computer(g, W: float, H: float, a: float) -> void:
	var t: float = g.cut_t
	var cx: float = W * 0.5
	var cy: float = H * 0.42
	g.draw_rect(Rect2(0, 9, W, H - 18), Color(0.06, 0.08, 0.13, a))
	_ground(g, W, H, a)
	var mood: int = 0
	var flick: float = 1.0
	if t < 1.6:
		mood = 0
	elif t < 2.3:
		mood = 1
		flick = 1.0 if int(t * 22.0) % 2 == 0 else 0.15
	elif t < 2.9:
		mood = 2
		flick = clamp(1.0 - (t - 2.3) / 0.6, 0.0, 1.0)
	elif t < 3.4:
		mood = 2
		flick = clamp((t - 2.9) / 0.5, 0.0, 1.0)
	else:
		mood = 3
	if mood == 1 or mood == 2:
		g.draw_rect(Rect2(0, 9, W, H - 18), Color(0.0, 0.0, 0.0, (1.0 - flick) * 0.6 * a))
	if mood == 0:
		_cap(g, "Главный компьютер: добрый ИИ следит за порядком.", a, Color(0.6, 0.9, 1.0))
	elif mood == 3:
		_cap(g, "> ВИРУС. Он больше не наш.", a, Color(1.0, 0.3, 0.3))
	else:
		_cap(g, "Вдруг свет мигнул...", a, Color(1.0, 0.8, 0.4))
	_computer(g, cx, cy, mood, flick, t, a)

static func _computer(g, cx: float, cy: float, mood: int, flick: float, t: float, a: float) -> void:
	if mood == 2 and flick < 0.5:
		# powered-down flicker: dark screen only
		draw_computer_frame(g, cx, cy, 30.0, Color(0.02, 0.03, 0.05, a), Color(0.14, 0.12, 0.14, a))
		g.draw_circle(Vector2(cx, cy + 26.0), 1.2, Color(0.6, 0.2, 0.2, a * 0.6))
		return
	if mood == 3:
		draw_computer_virus(g, cx, cy, 30.0, t, a)
	else:
		draw_computer_good(g, cx, cy, 30.0, t, a * flick)

static func _happy_face(g, cx: float, cy: float, w: float, h: float, t: float, a: float, flick: float) -> void:
	var glow := Color(0.6, 1.0, 1.0, a * flick)
	var blink: bool = int(t * 1.3) % 6 == 0
	var eh: float = 1.0 if blink else 6.0
	g.draw_rect(Rect2(cx - 16.0, cy - 8.0, 8.0, eh), glow)
	g.draw_rect(Rect2(cx + 8.0, cy - 8.0, 8.0, eh), glow)
	g.draw_circle(Vector2(cx - 22.0, cy + 4.0), 2.5, Color(0.4, 0.85, 1.0, a * 0.4 * flick))
	g.draw_circle(Vector2(cx + 22.0, cy + 4.0), 2.5, Color(0.4, 0.85, 1.0, a * 0.4 * flick))
	for i in range(9):
		var fx: float = cx - 16.0 + float(i) * 4.0
		var fy: float = cy + 8.0 + sin(float(i) / 8.0 * PI) * 6.0
		g.draw_rect(Rect2(fx, fy, 3.0, 3.0), glow)

static func _virus_face(g, cx: float, cy: float, w: float, h: float, t: float, a: float) -> void:
	for i in range(6):
		var gy: float = cy - h * 0.5 + fmod(float(i * 17) + t * 22.0, h)
		g.draw_rect(Rect2(cx - w * 0.5, gy, w, 1.0 + float(i % 3)), Color(0.2, 1.0, 0.3, a * 0.35))
	var red := Color(1.0, 0.25, 0.25, a)
	var grn := Color(0.3, 1.0, 0.4, a)
	g.draw_colored_polygon(PackedVector2Array([Vector2(cx - 18, cy - 10), Vector2(cx - 6, cy - 6), Vector2(cx - 18, cy - 2)]), red)
	g.draw_colored_polygon(PackedVector2Array([Vector2(cx + 18, cy - 10), Vector2(cx + 6, cy - 6), Vector2(cx + 18, cy - 2)]), red)
	g.draw_circle(Vector2(cx - 13, cy - 6), 1.6, Color(1, 1, 1, a))
	g.draw_circle(Vector2(cx + 13, cy - 6), 1.6, Color(1, 1, 1, a))
	var pts := PackedVector2Array()
	var n: int = 9
	for i in range(n):
		var mx: float = cx - 18.0 + 36.0 * float(i) / float(n - 1)
		var my: float = cy + 8.0 + (0.0 if i % 2 == 0 else 6.0)
		pts.append(Vector2(mx, my))
	for i in range(n - 1, -1, -1):
		var mx2: float = cx - 18.0 + 36.0 * float(i) / float(n - 1)
		pts.append(Vector2(mx2, cy + 16.0))
	g.draw_colored_polygon(pts, grn)
	if int(t * 8.0) % 3 == 0:
		g.draw_string(g.font, Vector2(cx - 10, cy + 2), "01X", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.4, 1.0, 0.5, a * 0.7))

# ---- phase 2: robots turn on the humans ------------------------------------

static func _scene_attack(g, W: float, H: float, a: float) -> void:
	var alarm: float = 0.5 + 0.5 * sin(g.menu_t * 6.0)
	g.draw_rect(Rect2(0, 9, W, H - 18), Color(0.14, 0.05, 0.06, a))
	g.draw_rect(Rect2(0, 9, W, H - 18), Color(0.6, 0.05, 0.08, a * 0.18 * alarm))
	_cap(g, "Роботы обратились против людей. Хаос.", a, Color(1.0, 0.5, 0.4))
	_ground(g, W, H, a)
	g.draw_rect(Rect2(W * 0.14 - 10.0, H * 0.68, 20.0, 4.0), Color(0.26, 0.2, 0.14, a))
	for i in range(4):
		var run: float = fmod(g.menu_t * 44.0 + i * 46.0, W + 30.0) - 15.0
		_person(g, run, H * 0.70 + (i % 2) * 4.0, a, Color(0.7, 0.55, 0.4, a), 1, g.menu_t * 9.0 + i, true)
	_robot(g, W * 0.30, H * 0.70, a, true, g.menu_t * 0.5, 0.0)
	_robot(g, W * 0.60, H * 0.70, a, true, g.menu_t * 0.5 + 1.0, 0.0)
	_robot(g, W * 0.85, H * 0.70, a, true, g.menu_t * 0.5 + 2.0, 0.0)
	for i in range(10):
		var sx: float = fmod(i * 61.0 + g.menu_t * 80.0, W)
		var sy2: float = H * 0.5 + fmod(i * 29.0, 60.0)
		g.draw_rect(Rect2(sx, sy2, 1.5, 1.5), Color(1.0, 0.7, 0.3, a * 0.7))

# ---- phase 3: the hero rises -----------------------------------------------

static func _scene_hero(g, W: float, H: float, a: float) -> void:
	g.draw_rect(Rect2(0, 9, W, H - 18), Color(0.06, 0.06, 0.10, a))
	g.draw_rect(Rect2(W * 0.5, 9, W * 0.5, H - 18), Color(0.3, 0.05, 0.08, a * 0.4))
	_cap(g, "Ты - инженер. Оборвать вирус у ядра можешь только ты.", a, Color(0.6, 1.0, 0.7))
	_ground(g, W, H, a)
	var hx: float = W * 0.42
	var hy: float = H * 0.70
	g.draw_colored_polygon(PackedVector2Array([Vector2(hx - 4, hy), Vector2(hx + 4, hy), Vector2(hx + 40, hy + 6), Vector2(hx + 30, hy + 6)]), Color(0, 0, 0, 0.3 * a))
	_hero(g, hx, hy, a, g.menu_t)
	var gl: float = 0.5 + 0.5 * sin(g.menu_t * 3.0)
	g.draw_circle(Vector2(hx + 3.0, hy - 24.0), 1.2, Color(0.6, 1.0, 1.0, a * gl))

static func _hero(g, x: float, y: float, a: float, t: float) -> void:
	var suit := Color(0.28, 0.52, 0.82, a)
	var lt := Color(0.48, 0.74, 1.0, a)
	var dk := Color(0.16, 0.30, 0.52, a)
	var metal := Color(0.72, 0.77, 0.84, a)
	var breathe: float = sin(t * 2.0) * 0.8
	g.draw_circle(Vector2(x, y + 1.0), 7.0, Color(0, 0, 0, 0.3 * a))
	g.draw_rect(Rect2(x - 5.0, y - 9.0, 4.0, 9.0), dk)
	g.draw_rect(Rect2(x + 1.0, y - 9.0, 4.0, 9.0), dk)
	g.draw_rect(Rect2(x - 5.0, y - 2.0, 4.0, 2.0), Color(0.08, 0.14, 0.24, a))
	g.draw_rect(Rect2(x + 1.0, y - 2.0, 4.0, 2.0), Color(0.08, 0.14, 0.24, a))
	g.draw_rect(Rect2(x - 6.0, y - 22.0 + breathe, 12.0, 13.0), suit)
	g.draw_rect(Rect2(x - 6.0, y - 22.0 + breathe, 12.0, 3.0), lt)
	g.draw_rect(Rect2(x - 6.0, y - 11.0 + breathe, 12.0, 2.0), dk)
	g.draw_rect(Rect2(x - 2.0, y - 18.0 + breathe, 4.0, 3.0), Color(0.3, 1.0, 0.9, a * 0.9))
	g.draw_rect(Rect2(x - 8.0, y - 21.0 + breathe, 2.5, 6.0), dk)
	g.draw_rect(Rect2(x + 5.5, y - 21.0 + breathe, 2.5, 6.0), dk)
	g.draw_rect(Rect2(x + 6.0, y - 18.0 + breathe, 6.0, 2.5), metal)
	g.draw_circle(Vector2(x + 12.0, y - 17.0 + breathe), 1.6, Color(0.5, 1.0, 1.0, a))
	g.draw_circle(Vector2(x, y - 26.0 + breathe), 5.0, lt)
	g.draw_circle(Vector2(x, y - 26.0 + breathe), 4.2, Color(0.10, 0.16, 0.24, a))
	g.draw_circle(Vector2(x + 2.0, y - 26.0 + breathe), 1.6, Color(0.5, 1.0, 1.0, a))
	g.draw_rect(Rect2(x - 3.5, y - 31.0 + breathe, 1.2, 3.0), metal)
	g.draw_circle(Vector2(x - 3.0, y - 31.5 + breathe), 1.0, Color(1.0, 0.4, 0.3, a))

static func _crt(g, W: float, H: float) -> void:
	var sy: float = 0.0
	while sy < H:
		g.draw_rect(Rect2(0.0, sy, W, 1.0), Color(0.0, 0.0, 0.0, 0.10))
		sy += 3.0
	g.draw_rect(Rect2(0.0, 0.0, W, 6.0), Color(0.0, 0.0, 0.0, 0.35))
	g.draw_rect(Rect2(0.0, H - 6.0, W, 6.0), Color(0.0, 0.0, 0.0, 0.35))
	g.draw_rect(Rect2(0.0, 0.0, 6.0, H), Color(0.0, 0.0, 0.0, 0.30))
	g.draw_rect(Rect2(W - 6.0, 0.0, 6.0, H), Color(0.0, 0.0, 0.0, 0.30))
