extends Node2D

# Phone-first twin-stick controls. Layout and scale are editable in-game.
var game
var move_vec := Vector2.ZERO
var aim_vec := Vector2.RIGHT
var firing := false
var dash_pressed := false
var alt_pressed := false
var enabled := true
var editing := false
var ui_scale := 1.0
var layout_shift := Vector2.ZERO
var button_offsets: Dictionary = {}

var move_touch := -1
var aim_touch := -1
var drag_touch := -1
var drag_control := ""
var move_origin := Vector2(58, 145)
var aim_origin := Vector2(286, 145)
var touch_pos := {}
var button_down := {}
const SAVE := "user://mobile_controls.cfg"

func _ready() -> void:
	z_index = 500
	_load_layout()
	set_process_input(true)
	queue_redraw()

func _process(_delta: float) -> void:
	visible = enabled and game != null and game.state != game.St.BOOT_ENGINE
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not enabled or game == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed: _touch_down(event.index, event.position)
		else: _touch_up(event.index, event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		_touch_drag(event.index, event.position)
		get_viewport().set_input_as_handled()
	# Mouse emulation makes the editor preview usable.
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: _touch_down(999, event.position)
		else: _touch_up(999, event.position)
	elif event is InputEventMouseMotion and 999 in touch_pos:
		_touch_drag(999, event.position)

func _touch_down(id: int, p: Vector2) -> void:
	touch_pos[id] = p
	if editing:
		var hit := _control_at(p)
		if hit != "": drag_touch = id; drag_control = hit
		return
	if _circle_hit(p, _gear_pos(), 13.0):
		editing = true; move_vec = Vector2.ZERO; firing = false
		return
	if game.state == game.St.MENU:
		if p.y > 105: game.mobile_action("start")
		return
	if game.state == game.St.INTRO or game.state == game.St.DIALOG or game.state == game.St.BOSS_INTRO or game.state == game.St.NOVA_CUT or game.state == game.St.ENDING or game.state == game.St.DEATH:
		game.mobile_action("continue")
		return
	if game.state == game.St.CHOICE:
		var third := 352.0 / 3.0
		game.mobile_action("choice" + str(clampi(int(p.x / third) + 1, 1, 3)))
		return
	if _circle_hit(p, _button_pos("dash"), 16.0 * ui_scale): dash_pressed = true
	elif _circle_hit(p, _button_pos("nova"), 14.0 * ui_scale): game.mobile_action("nova")
	elif _circle_hit(p, _button_pos("use"), 13.0 * ui_scale): game.mobile_action("use")
	elif _circle_hit(p, _button_pos("weapon"), 12.0 * ui_scale): game.mobile_action("weapon")
	elif _circle_hit(p, _button_pos("item"), 11.0 * ui_scale): game.mobile_action("item")
	elif _circle_hit(p, _button_pos("shield"), 11.0 * ui_scale): game.mobile_action("shield")
	elif _circle_hit(p, _button_pos("map"), 10.0 * ui_scale): game.mobile_action("map")
	elif p.x < 145:
		move_touch = id; move_origin = _clamp_stick_origin(p, true); _update_move(p)
	elif p.x > 190:
		aim_touch = id; aim_origin = _clamp_stick_origin(p, false); _update_aim(p); firing = true

func _touch_drag(id: int, p: Vector2) -> void:
	touch_pos[id] = p
	if editing and id == drag_touch:
		_set_control_pos(drag_control, p)
	elif id == move_touch: _update_move(p)
	elif id == aim_touch: _update_aim(p); firing = true

func _touch_up(id: int, _p: Vector2) -> void:
	touch_pos.erase(id)
	if id == move_touch: move_touch = -1; move_vec = Vector2.ZERO
	if id == aim_touch: aim_touch = -1; firing = false
	if id == drag_touch: drag_touch = -1; drag_control = ""; _save_layout()
	dash_pressed = false

func _update_move(p: Vector2) -> void:
	move_vec = ((p - move_origin) / (26.0 * ui_scale)).limit_length(1.0)

func _update_aim(p: Vector2) -> void:
	var v := ((p - aim_origin) / (25.0 * ui_scale)).limit_length(1.0)
	if v.length() > 0.12: aim_vec = v.normalized()

func consume_dash() -> bool:
	var v := dash_pressed
	dash_pressed = false
	return v

func _button_pos(name: String) -> Vector2:
	var base := {
		"dash": Vector2(218,151), "nova":Vector2(252,116), "use":Vector2(319,104),
		"weapon":Vector2(334,139), "item":Vector2(235,82), "shield":Vector2(274,76), "map":Vector2(323,24)
	}
	return base[name] + Vector2(button_offsets.get(name, Vector2.ZERO))

func _gear_pos() -> Vector2: return Vector2(346, 16)
func _circle_hit(p: Vector2, c: Vector2, r: float) -> bool: return p.distance_to(c) <= r
func _clamp_stick_origin(p: Vector2, left: bool) -> Vector2:
	return Vector2(clampf(p.x, 34.0, 112.0) if left else clampf(p.x, 240.0, 320.0), clampf(p.y, 122.0, 164.0))

func _control_at(p: Vector2) -> String:
	if _circle_hit(p, move_origin, 30*ui_scale): return "move"
	if _circle_hit(p, aim_origin, 30*ui_scale): return "aim"
	for n in ["dash","nova","use","weapon","item","shield","map"]:
		if _circle_hit(p,_button_pos(n),18*ui_scale): return n
	if _circle_hit(p, Vector2(176,112), 18): return "scale"
	if _circle_hit(p, Vector2(176,151), 22): return "done"
	return ""

func _set_control_pos(name: String, p: Vector2) -> void:
	if name == "move": move_origin = p
	elif name == "aim": aim_origin = p
	elif name == "scale": ui_scale = clampf((192.0 - p.y) / 70.0, 0.72, 1.35)
	elif name == "done": editing = false; _save_layout()
	else:
		# Buttons move as a coherent cluster, preserving muscle memory.
		button_offsets[name] = Vector2(button_offsets.get(name, Vector2.ZERO)) + (p - _button_pos(name))

func _save_layout() -> void:
	var c:=ConfigFile.new(); c.set_value("touch","scale",ui_scale); c.set_value("touch","move",move_origin); c.set_value("touch","aim",aim_origin); c.set_value("touch","shift",layout_shift); c.set_value("touch","buttons",button_offsets); c.save(SAVE)
func _load_layout() -> void:
	var c:=ConfigFile.new()
	if c.load(SAVE)==OK:
		ui_scale=float(c.get_value("touch","scale",1.0)); move_origin=c.get_value("touch","move",move_origin); aim_origin=c.get_value("touch","aim",aim_origin); layout_shift=c.get_value("touch","shift",Vector2.ZERO); button_offsets=c.get_value("touch","buttons",{})

func _draw() -> void:
	if not visible: return
	if not editing and not (game.state == game.St.PLAY or game.state == game.St.VIRUS or game.state == game.St.BOSS):
		if game.state == game.St.MENU: _label("КОСНИСЬ ЭКРАНА, ЧТОБЫ НАЧАТЬ",176,178,8,Color(0.65,0.95,1.0))
		return
	if editing: draw_rect(Rect2(0,0,352,192),Color(0.02,0.04,0.07,0.72)); _label("НАСТРОЙКА УПРАВЛЕНИЯ",176,18,10,Color(0.65,0.95,1)); _label("перетаскивай элементы",176,31,7,Color(0.65,0.75,0.82)); draw_circle(Vector2(176,112),18,Color(0.2,0.65,0.8,0.35)); _label("РАЗМЕР",176,115,6,Color(0.85,1,1)); draw_circle(Vector2(176,151),22,Color(0.25,0.85,0.55,0.55)); _label("ГОТОВО",176,154,7,Color(0.9,1,0.9))
	_draw_stick(move_origin, move_vec, Color(0.35,0.8,1.0), "ХОД")
	_draw_stick(aim_origin, aim_vec if firing else Vector2.ZERO, Color(1.0,0.48,0.32), "ОГОНЬ")
	_draw_button("dash","РЫВ",Color(0.35,0.8,1.0)); _draw_button("nova","NOVA",Color(0.3,1.0,0.82)); _draw_button("use","E",Color(0.9,0.9,0.65)); _draw_button("weapon","ОРУЖ",Color(0.8,0.65,1.0)); _draw_button("item","ГРАН",Color(1.0,0.58,0.3)); _draw_button("shield","ЩИТ",Color(0.45,0.72,1.0)); _draw_button("map","КАРТА",Color(0.6,0.78,0.9))
	draw_circle(_gear_pos(),8,Color(0.08,0.13,0.18,0.8)); _label("⚙",_gear_pos().x,_gear_pos().y+3,8,Color(0.7,0.9,1))

func _draw_stick(origin:Vector2, vec:Vector2, col:Color, text:String)->void:
	var r:=28.0*ui_scale; draw_circle(origin,r,Color(0.03,0.07,0.1,0.46)); draw_arc(origin,r,0,TAU,32,Color(col.r,col.g,col.b,0.48),1.5); draw_circle(origin+vec*r*0.62,11*ui_scale,Color(col.r,col.g,col.b,0.48)); _label(text,origin.x,origin.y+r+8,6,Color(col.r,col.g,col.b,0.78))
func _draw_button(name:String,text:String,col:Color)->void:
	var radii={"dash":16,"nova":14,"use":13,"weapon":12,"item":11,"shield":11,"map":10}; var r:float=float(radii[name])*ui_scale; var p:=_button_pos(name); draw_circle(p,r,Color(0.035,0.075,0.11,0.72)); draw_arc(p,r,0,TAU,24,Color(col.r,col.g,col.b,0.7),1.3); _label(text,p.x,p.y+2,6,Color(col.r,col.g,col.b,0.95))
func _label(t:String,x:float,y:float,fs:int,c:Color)->void:
	if game==null:return
	var w:float=game.font.get_string_size(t,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x; draw_string(game.font,Vector2(x-w*0.5,y),t,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,c)
