extends CanvasLayer
## Minijocul cu zăvorul lui Nea Ilie (prim-plan peste drum).
## Tragi cu degetul (sau mouse-ul) în cerc în jurul zăvorului, ca să răsucești sârma de cupru.
## - prea repede: sârma se întinde prea tare și se rupe (o iei de la capăt);
## - dacă te oprești: sârma se desface încet;
## - 4 ture bune și zăvorul ține.
## Fundalul e un prim-plan desenat (art/final/zavor_prim_plan.png); sârma se desenează pixel cu pixel.

signal finished(result: String)

const TURNS := 4.0
## zăvorul în prim-plan (de reglat după desen): centrul în jurul căruia răsucești și bara pe care se strânge sârma
var center := Vector2(320, 175)
var bar := Rect2(286, 168, 70, 14)
const COPPER := Color(0.85, 0.5, 0.25)
const COPPER_HI := Color(1.0, 0.78, 0.5)

var _root: Control
var _draw: Control
var _progress := 0.0        # ture răsucite
var _tension := 0.0         # 0..1 bine, peste 1 = prea strâns
var _over_t := 0.0          # cât timp a stat prea strâns
var _dragging := false
var _last_ang := 0.0
var _finger := Vector2.ZERO
var _idle := 0.0
var _snap_flash := 0.0
var _done := false
var _speed := 0.0


func _ready() -> void:
	layer = 5
	_root = Control.new()
	_root.size = Vector2(Game.W, Game.H)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(_on_input)
	add_child(_root)
	if ResourceLoader.exists("res://art/final/zavor_prim_plan.png"):
		var bg := TextureRect.new()
		bg.texture = load("res://art/final/zavor_prim_plan.png")
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(bg)
		if ResourceLoader.exists("res://art/final/zavor_prim_plan.json"):
			var j: Dictionary = JSON.parse_string(FileAccess.open("res://art/final/zavor_prim_plan.json", FileAccess.READ).get_as_text())
			center = Vector2(j["center"][0], j["center"][1])
			bar = Rect2(j["bar"][0], j["bar"][1], j["bar"][2], j["bar"][3])
	else:
		var ph := ColorRect.new()
		ph.color = Color("#2a1c1c")
		ph.size = _root.size
		ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(ph)
	_draw = Control.new()
	_draw.size = _root.size
	_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw.draw.connect(_on_draw)
	_root.add_child(_draw)
	var tip := Label.new()
	tip.text = "Trage cu degetul în cerc, în jurul zăvorului"
	tip.position = Vector2(0, 8)
	tip.size = Vector2(Game.W, 24)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	tip.add_theme_color_override("font_shadow_color", Color.BLACK)
	tip.add_theme_constant_override("shadow_offset_y", 1)
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(tip)
	_finger = center + Vector2(40, 30)


func _on_input(e: InputEvent) -> void:
	if _done:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_dragging = e.pressed
		if e.pressed:
			_finger = e.position
			_last_ang = (e.position - center).angle()
	elif e is InputEventMouseMotion and _dragging:
		_finger = e.position
		var ang: float = (e.position - center).angle()
		var dlt := wrapf(ang - _last_ang, -PI, PI)
		_last_ang = ang
		if (e.position - center).length() > 14.0:    # prea aproape de centru nu se numără
			_progress += absf(dlt) / TAU
			_speed += absf(dlt)
			_idle = 0.0


func _process(d: float) -> void:
	if _done:
		return
	# tensiunea urmează viteza de răsucire (rad/s), netezită
	var rad_s: float = _speed / maxf(d, 0.001)
	_speed = 0.0
	_tension = lerpf(_tension, clampf(rad_s / 10.0, 0.0, 1.6), clampf(d * 6.0, 0.0, 1.0))
	if _tension > 1.0:
		_over_t += d
		if _over_t > 0.3:
			_snap()
	else:
		_over_t = 0.0
	_idle += d
	if _idle > 0.7 and _progress > 0.0:
		_progress = maxf(0.0, _progress - d * 0.6)   # sârma lăsată se desface
		_tension = maxf(0.0, _tension - d)
	_snap_flash = maxf(0.0, _snap_flash - d)
	if _progress >= TURNS:
		_done = true
		_draw.queue_redraw()
		await get_tree().create_timer(0.6).timeout
		finished.emit("ok")
		return
	_draw.queue_redraw()


func _snap() -> void:
	_progress = 0.0
	_tension = 0.0
	_over_t = 0.0
	_dragging = false
	_snap_flash = 0.4
	Game.shake(3.0, 0.25)
	var lines := ["Pac! S-a rupt. Prea tare.", "Iar s-a rupt... Mai domol, Romică.", "Sârma vrea răbdare, nu forță."]
	await Game.say("Romică", lines.pick_random())


func _on_draw() -> void:
	# turele deja strânse: spirale de cupru pe bară, din stânga spre dreapta
	var half := int(_progress * 2.0)
	var step := bar.size.x / (TURNS * 2.0 + 1.0)
	for h in half:
		var x := bar.position.x + step * (h + 1)
		var top := Vector2(x, bar.position.y - 2)
		var bot := Vector2(x + step * 0.8, bar.end.y + 2)
		if h % 2 == 0:
			_draw.draw_line(top.round(), bot.round(), COPPER, 2.0)
			_draw.draw_line(top.round() + Vector2(1, 0), (top + (bot - top) * 0.5).round() + Vector2(1, 0), COPPER_HI, 1.0)
		else:
			_draw.draw_line(bot.round(), (top + Vector2(step, 0)).round(), COPPER.darkened(0.45), 2.0)
	# capătul de sârmă tras cu degetul: întins drept când e strâns, lăsat în jos când e moale
	var start := Vector2(bar.position.x + step * (half + 1), bar.position.y + (0.0 if half % 2 == 0 else bar.size.y))
	var tight := clampf(_tension, 0.0, 1.0)
	var sag := (1.0 - tight) * 28.0
	var mid := (start + _finger) / 2.0 + Vector2(0, sag)
	var col := COPPER.lerp(Color(1.0, 0.95, 0.75), clampf((_tension - 0.6) * 2.0, 0.0, 1.0))
	var pts := PackedVector2Array()
	for k in 13:
		var t := k / 12.0
		pts.append(((1 - t) * (1 - t) * start + 2 * (1 - t) * t * mid + t * t * _finger).round())
	_draw.draw_polyline(pts, col, 2.0)
	_draw.draw_polyline(pts, Color(col.lightened(0.3), 0.6), 1.0)
	if _tension > 0.85:   # sârma „cântă” când e aproape să se rupă
		_draw.draw_circle(start, 2.0 + randf() * 1.5, Color(1, 1, 0.8, 0.5))
	if _snap_flash > 0.0:
		_draw.draw_rect(Rect2(Vector2.ZERO, _draw.size), Color(1, 1, 1, _snap_flash * 0.5))
	if _done:
		_draw.draw_rect(Rect2(Vector2.ZERO, _draw.size), Color(0, 0, 0, 0.25))
