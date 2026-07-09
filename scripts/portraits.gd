extends RefCounted
class_name Portraits

# Framed dialogue box with a big pixel portrait of the speaker. Speaker is
# inferred from the line so existing dialogue arrays need no restructuring:
#   "NOVA: ..."               -> Nova (teal)
#   "ТЕРМИНАЛ..."/"ЭКРАН..."  -> system/terminal (green)
#   anything else             -> the engineer (blue)

static func speaker_of(line: String) -> String:
	if line.begins_with("NOVA"):
		return "nova"
	if line.begins_with("ТЕРМИНАЛ") or line.begins_with("СИСТЕМА") or line.begins_with("ЭКРАН") or line.begins_with("ЯДРО") or line.begins_with(">"):
		return "system"
	return "hero"

static func strip_prefix(line: String) -> String:
	var idx: int = line.find(": ")
	if idx > 0 and idx < 12:
		return line.substr(idx + 2)
	return line

static func _accent(who: String) -> Color:
	if who == "nova": return Color(0.4,1.0,0.9)
	if who == "system": return Color(0.4,1.0,0.5)
	return Color(0.5,0.8,1.0)

static func dialogue(g, line: String, shown: String, infected: bool = false) -> void:
	var W: float = g.COLS * g.TILE
	var H: float = g.ROWS * g.TILE
	var who: String = speaker_of(line)
	var acc: Color = _accent(who)
	var enter: float = clamp((g.menu_t - g.dlg_t0) / 0.22, 0.0, 1.0)
	var box_h: float = 70.0
	var y: float = H - box_h * enter
	# Keep the scene visible. A restrained dim focuses attention without killing context.
	g.draw_rect(Rect2(0, 0, W, H), Color(0.015, 0.025, 0.04, 0.28 * enter))
	g.draw_rect(Rect2(0, y - 5, W, box_h + 5), Color(0.025, 0.045, 0.07, 0.98))
	g.draw_rect(Rect2(0, y - 5, W, 2), acc)
	# portrait well with an asymmetric silhouette, not a floating card
	var pw: float = 62.0
	g.draw_rect(Rect2(0, y - 3, pw, box_h + 3), Color(0.045, 0.075, 0.105))
	g.draw_colored_polygon(PackedVector2Array([Vector2(pw-10,y-3),Vector2(pw,y-3),Vector2(pw-12,H),Vector2(pw-22,H)]), Color(acc.r,acc.g,acc.b,0.14))
	var talking: bool = strip_prefix(shown).length() < strip_prefix(line).length()
	match who:
		"nova": _nova(g, 29, y + 36, g.menu_t, infected, talking)
		"system": _terminal(g, 29, y + 33, g.menu_t)
		_: _hero(g, 29, y + 37, g.menu_t, talking)
	var nm: String = "ИНЖЕНЕР"
	if who == "nova": nm = "NOVA // СПУТНИК"
	elif who == "system": nm = "СЕТЬ КОМПЛЕКСА"
	# speaker label
	var tx: float = 68.0
	g.draw_string(g.font, Vector2(tx, y + 12), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, acc)
	g.draw_rect(Rect2(tx, y + 16, 28, 1), Color(acc.r,acc.g,acc.b,0.55))
	# text, generous leading and width
	var body: String = strip_prefix(shown)
	g.draw_multiline_string(g.font, Vector2(tx, y + 29), body, HORIZONTAL_ALIGNMENT_LEFT, W - tx - 12, 9, 3, Color(0.9,0.96,0.99))
	# progress and input affordance
	var step: String = str(g.dialog_idx + 1) + " / " + str(g.dialog_lines.size())
	g.draw_string(g.font, Vector2(tx, H - 5), step, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.45,0.62,0.72))
	if not talking and int(g.menu_t * 2.4) % 2 == 0:
		g.draw_string(g.font, Vector2(W - 66, H - 5), "КОСНИСЬ ЭКРАНА  >", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(acc.r,acc.g,acc.b,0.9))
	elif talking:
		var pulse: float = 0.45 + 0.35 * sin(g.menu_t * 8.0)
		g.draw_rect(Rect2(W - 14, y + 10, 6, 2), Color(acc.r,acc.g,acc.b,pulse))

static func _hero(g, cx: float, cy: float, t: float, talking: bool = false) -> void:
	var bob: float = sin(t*2.0)*0.6
	cy += bob
	var suit := Color(0.26,0.50,0.80)
	var suit_lt := Color(0.5,0.76,1.0)
	var suit_dk := Color(0.14,0.28,0.5)
	var skin := Color(0.86,0.7,0.56)
	var metal := Color(0.72,0.78,0.86)
	# subtle rim backlight
	g.draw_circle(Vector2(cx, cy-4), 20.0, Color(0.3,0.6,1.0,0.06))
	# shoulders / chest armor
	g.draw_rect(Rect2(cx-15, cy+7, 30, 13), suit_dk)
	g.draw_rect(Rect2(cx-14, cy+7, 28, 12), suit)
	g.draw_rect(Rect2(cx-14, cy+7, 28, 3), suit_lt)
	g.draw_rect(Rect2(cx-16, cy+8, 3, 10), suit_dk)
	g.draw_rect(Rect2(cx+13, cy+8, 3, 10), suit_dk)
	# chest core reactor
	var rp: float = 0.6 + 0.4*sin(t*3.0)
	g.draw_circle(Vector2(cx, cy+13), 3.6, Color(0.2,0.9,1.0,rp))
	g.draw_circle(Vector2(cx, cy+13), 1.8, Color(0.9,1.0,1.0,rp))
	# neck seal
	g.draw_rect(Rect2(cx-4, cy+4, 8, 4), metal.darkened(0.2))
	# helmet dome with plating
	g.draw_rect(Rect2(cx-13, cy-16, 26, 22), suit)
	g.draw_rect(Rect2(cx-13, cy-16, 26, 3), suit_lt)
	g.draw_rect(Rect2(cx-13, cy-8, 26, 1), suit_dk)
	g.draw_rect(Rect2(cx-15, cy-10, 2, 12), suit_dk)
	g.draw_rect(Rect2(cx+13, cy-10, 2, 12), suit_dk)
	# dark visor recess
	g.draw_rect(Rect2(cx-10, cy-10, 20, 10), Color(0.05,0.09,0.15))
	# visor glow scan-bar
	var glow: float = 0.6+0.4*sin(t*3.0)
	g.draw_rect(Rect2(cx-8, cy-8, 16, 4), Color(0.35,0.9,1.0, glow))
	g.draw_rect(Rect2(cx-8, cy-8 + fmod(t*8.0, 4.0), 16, 1), Color(0.8,1.0,1.0, glow*0.8))
	# cheek vents
	for vi in range(3):
		g.draw_rect(Rect2(cx-11, cy-3 + vi*2, 2, 1), suit_dk)
		g.draw_rect(Rect2(cx+9, cy-3 + vi*2, 2, 1), suit_dk)
	# antenna with blinking tip
	g.draw_rect(Rect2(cx+9, cy-21, 2, 6), metal)
	var bl: float = 0.4+0.6*abs(sin(t*4.0))
	g.draw_circle(Vector2(cx+10, cy-22), 1.6, Color(1.0,0.4,0.3, bl))
	# talking mouth-light under visor
	if talking:
		var mf: float = 0.5 + 0.5 * sin(t * 22.0)
		g.draw_rect(Rect2(cx-4, cy+1, 8, 1.0 + mf * 1.6), Color(0.4,0.95,1.0, 0.55))

static func _nova(g, cx: float, cy: float, t: float, infected: bool, talking: bool = false) -> void:
	var bob: float = sin(t*3.0)*1.0
	cy += bob
	var shell := Color(0.14,0.55,0.6)
	var shell_lt := Color(0.4,0.98,1.0)
	var shell_dk := Color(0.07,0.32,0.36)
	var eye := Color(0.5,1.0,0.95)
	if infected:
		shell = Color(0.4,0.08,0.1); shell_lt = Color(0.85,0.22,0.25); shell_dk = Color(0.22,0.03,0.05); eye = Color(1.0,0.25,0.2)
	# halo
	g.draw_circle(Vector2(cx, cy-2), 20.0, Color(shell_lt.r, shell_lt.g, shell_lt.b, 0.07))
	# side thruster fins
	var fin: float = sin(t*2.5)*1.2
	g.draw_rect(Rect2(cx-17, cy-2+fin, 4, 8), shell_dk)
	g.draw_rect(Rect2(cx+13, cy-2-fin, 4, 8), shell_dk)
	g.draw_circle(Vector2(cx-15, cy+6+fin), 1.6, shell_lt)
	g.draw_circle(Vector2(cx+15, cy+6-fin), 1.6, shell_lt)
	# rounded body shell with plating
	g.draw_rect(Rect2(cx-13, cy-13, 26, 25), shell_dk)
	g.draw_rect(Rect2(cx-12, cy-12, 24, 23), shell)
	g.draw_rect(Rect2(cx-12, cy-12, 24, 3), shell_lt)
	g.draw_rect(Rect2(cx-12, cy+9, 24, 2), shell_dk)
	g.draw_rect(Rect2(cx-6, cy+2, 12, 1), shell_dk)
	# glossy top highlight
	g.draw_circle(Vector2(cx-4, cy-8), 3.5, Color(0.8,1.0,1.0,0.25))
	# face recess
	g.draw_rect(Rect2(cx-9, cy-9, 18, 11), Color(0.03,0.13,0.16) if not infected else Color(0.12,0.02,0.04))
	# one big expressive eye, tracks + blinks
	var look: float = sin(t*1.5)*2.2
	if infected and int(t*8.0)%5==0: look = randf_range(-3,3)
	var blink := int(t*1.2)%9==0
	if blink:
		g.draw_rect(Rect2(cx-4, cy-3, 8, 1.5), eye)
	else:
		g.draw_circle(Vector2(cx+look, cy-3), 3.4, Color(eye.r,eye.g,eye.b,0.4))
		g.draw_circle(Vector2(cx+look, cy-3), 2.2, eye)
		g.draw_circle(Vector2(cx+look, cy-3), 1.0, Color(1,1,1))
	# chest core light
	var cp: float = 0.55+0.45*sin(t*3.0)
	g.draw_circle(Vector2(cx, cy+6), 2.4, Color(shell_lt.r,shell_lt.g,shell_lt.b,cp))
	# antenna
	g.draw_rect(Rect2(cx-1, cy-17, 2, 4), shell_lt)
	g.draw_circle(Vector2(cx, cy-18), 1.5, eye)
	# hover thruster glow
	g.draw_rect(Rect2(cx-3, cy+11, 6, 2), Color(0.3,0.8,1.0, 0.4+0.3*sin(t*10.0)))
	if talking:
		var nf: float = 0.5 + 0.5 * sin(t * 20.0)
		g.draw_rect(Rect2(cx-2, cy+1, 4, 0.8 + nf * 1.6), Color(0.6,1.0,0.95, 0.6))

static func _terminal(g, cx: float, cy: float, t: float) -> void:
	g.draw_rect(Rect2(cx-16, cy-14, 32, 26), Color(0.1,0.11,0.13))
	g.draw_rect(Rect2(cx-14, cy-12, 28, 20), Color(0.04,0.14,0.07))
	var flick: float = 0.6+0.4*sin(t*8.0)
	for i in range(6):
		g.draw_rect(Rect2(cx-12, cy-10+i*3, 6+i*3, 1), Color(0.2,0.9,0.4, flick))
	g.draw_rect(Rect2(cx-6, cy+12, 12, 3), Color(0.15,0.18,0.22))
