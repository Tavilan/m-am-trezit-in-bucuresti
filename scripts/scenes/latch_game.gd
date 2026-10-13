extends CanvasLayer
## Minijocul cu zăvorul lui Nea Ilie (prim-plan peste drum).
## Tragi cu degetul (sau mouse-ul) în cerc în jurul zăvorului, ca să răsucești sârma de cupru.
## - prea repede: sârma se întinde prea tare și se rupe (o iei de la capăt);
##   cu cât e mai strânsă, cu atât trebuie răsucită mai încet;
## - prea încet sau oprit: sârma alunecă și se desface;
## - în rugină se agață: când se agață, stai o clipă cu degetul pe loc, altfel se rupe;
## - învârtitul se numără doar în jurul zăvorului (nu prea aproape, nu prea departe);
## - 5 ture și zăvorul ține.
## Fundalul e un prim-plan desenat (art/final/zavor_prim_plan.png); sârma se desenează pixel cu pixel.

signal finished(result: String)

const TURNS := 5.0
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
var _ang_v := 0.0
var _snags: Array = []      # la ce tură se agață sârma în rugină
var _snag := false          # acum e agățată
var _snag_still := 0.0      # cât a stat degetul pe loc de când s-a agățat
var _moved := false         # s-a mișcat degetul în cadrul ăsta
var _hint: Label


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
	_hint = Label.new()
	_hint.position = Vector2(0, Game.H - 34)
	_hint.size = Vector2(Game.W, 24)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_color", Color(1, 0.9, 0.7, 0.9))
	_hint.add_theme_color_override("font_shadow_color", Color.BLACK)
	_hint.add_theme_constant_override("shadow_offset_y", 1)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hint)
	_finger = center + Vector2(40, 30)
	_new_snags()


func _new_snags() -> void:
	_snags = [randf_range(1.0, 2.0), randf_range(2.6, 3.6), randf_range(4.0, 4.7)]


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
		var r: float = (e.position - center).length()
		if r > 22.0 and r < 110.0:    # doar în jurul zăvorului se strânge sârma
			if not _snag:             # agățată în rugină nu mai înaintează
				_progress += absf(dlt) / TAU
			_speed += absf(dlt)
			_idle = 0.0
			if absf(dlt) > 0.004:
				_moved = true


func _process(d: float) -> void:
	if _done:
		return
	# viteza unghiulară netezită (evenimentele de atingere nu vin în fiecare cadru)
	_ang_v = lerpf(_ang_v, _speed / maxf(d, 0.001), clampf(d * 8.0, 0.0, 1.0))
	var rad_s := _ang_v
	_speed = 0.0
	# cu cât sunt mai multe ture pe zăvor, cu atât sârma e mai țeapănă: se rupe la viteze tot mai mici
	var limit := lerpf(8.0, 2.8, clampf(_progress / TURNS, 0.0, 1.0))
	var target := rad_s / limit
	# agățată în rugină: orice mișcare o întinde de trei ori mai tare; stai pe loc și se desprinde
	if not _snags.is_empty() and _progress >= _snags[0] and not _snag:
		_snag = true
		_snag_still = 0.0
		_hint.text = "S-a agățat în rugină... stai o clipă."
	if _snag:
		if _ang_v > 0.5:   # tragi de ea agățată: se întinde repede
			target = 0.6 + _ang_v / limit * 3.0
			_snag_still = 0.0
		else:
			_snag_still += d
			if _snag_still > 0.5:
				_snag = false
				_snags.pop_front()
				_hint.text = ""
	_moved = false
	if OS.has_feature("web"):   # pentru testele automate din browser
		JavaScriptBridge.eval("window.latch={p:%f,snag:%s}" % [_progress, "true" if _snag else "false"])
	_tension = lerpf(_tension, clampf(target, 0.0, 1.6), clampf(d * 10.0, 0.0, 1.0))
	if _tension > 1.0:
		_over_t += d
		if _over_t > (0.55 if _snag else 0.18):   # agățată: lași o clipă de reacție
			_snap()
	else:
		_over_t = 0.0
	_idle += d
	# prea încet sau oprit (și nu e agățată): sârma alunecă înapoi
	if not _snag and _progress > 0.0 and (_idle > 0.35 or (_dragging and rad_s < 1.0)):
		_progress = maxf(0.0, _progress - d * (0.9 if _idle > 0.35 else 0.35))
		_tension = maxf(0.0, _tension - d)
	_snap_flash = maxf(0.0, _snap_flash - d)
	if _progress >= TURNS:
		_done = true
		_hint.text = ""
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
	_snag = false
	_hint.text = ""
	_new_snags()
	_snap_flash = 0.4
	Game.shake(3.0, 0.25)
	var lines := ["Pac! Se rupse. Fir-ar mama ei de sârmă.", "Iar se rupse... Mai domol, Romică, că nu-i frâna de la tractor.", "Sârma vrea răbdare, nu putere.", "Futu-i... De la capăt."]
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
			_draw.draw_line(top.round() + Vector2(1, 2), bot.round() + Vector2(1, 2), Color(0, 0, 0, 0.35), 3.0)   # umbra pe bară
			_draw.draw_line(top.round(), bot.round(), COPPER, 3.0)
			_draw.draw_line(top.round() + Vector2(1, 0), (top + (bot - top) * 0.5).round() + Vector2(1, 0), COPPER_HI, 1.0)
		else:
			_draw.draw_line(bot.round(), (top + Vector2(step, 0)).round(), COPPER.darkened(0.55), 3.0)
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
	_draw.draw_polyline(pts, col, 3.0)
	_draw.draw_polyline(pts, Color(col.lightened(0.3), 0.6), 1.0)
	if _snag:   # agățată în rugină: un cot strâmb lângă zăvor
		var k1 := start + Vector2(4, -3)
		var k2 := start + Vector2(7, 2)
		_draw.draw_polyline(PackedVector2Array([start.round(), k1.round(), k2.round()]), COPPER.darkened(0.2), 3.0)
	if _tension > 0.85:   # sârma „cântă” când e aproape să se rupă
		_draw.draw_circle(start, 2.0 + randf() * 1.5, Color(1, 1, 0.8, 0.5))
	if _snap_flash > 0.0:
		_draw.draw_rect(Rect2(Vector2.ZERO, _draw.size), Color(1, 1, 1, _snap_flash * 0.5))
	if _done:
		_draw.draw_rect(Rect2(Vector2.ZERO, _draw.size), Color(0, 0, 0, 0.25))
