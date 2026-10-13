extends CanvasLayer
## Minijocul cu zăvorul lui Nea Ilie (prim-plan peste drum). Cum se face și în realitate:
##   1. ÎNFĂȘORI: treci sârma prin gaura plăcuței rupte și peste bară, tură după tură, ca plăcuța să stea
##      lipită de bară. Tragi în cerc în jurul zăvorului. Prea repede: sârma se întinde și se rupe.
##      Te oprești: se desface. Se agață în rugină: stai o clipă pe loc, altfel se rupe.
##      Cu cât sunt mai multe ture, cu atât sârma e mai țeapănă (trebuie mai încet).
##   2. RĂSUCEȘTI CAPETELE CU CLEȘTELE: învârți în cerc ca să răsucești cele două capete împreună.
##      Codița se strânge tură cu tură; când e strânsă (6 ture) îi dai drumul. Dacă mai răsucești peste
##      măsură, sârma (care se întărește la răsucit) crapă și o iei de la capăt cu răsucitul.
##   3. ÎNDOI CODIȚA: tragi codița în jos, lipită de plăcuță, să nu agațe câinele.
## Fundal: art/final/zavor_prim_plan.png; mâna cu cleștele: art/final/mana_cleste_zavor.png (dacă există).

signal finished(result: String)

const TURNS := 5.0
const TWIST_OK := 6.0      # de aici codița ține
const TWIST_MAX := 7.5     # peste asta crapă
var center := Vector2(437, 160)   # în jurul lui se învârte (bară + plăcuță)
var hole := Vector2(437, 186)     # gaura plăcuței rupte, prin care trece sârma
var bar_top := 136.0
var coil_x := Vector2(424, 452)   # între ce x-uri se așază turele
const COPPER := Color(0.85, 0.5, 0.25)
const COPPER_HI := Color(1.0, 0.8, 0.55)
const COPPER_LO := Color(0.42, 0.22, 0.1)

var _root: Control
var _draw: Control
var _phase := 1
var _progress := 0.0
var _tension := 0.0
var _over_t := 0.0
var _dragging := false
var _last_ang := 0.0
var _finger := Vector2.ZERO
var _idle := 0.0
var _snap_flash := 0.0
var _done := false
var _speed := 0.0
var _ang_v := 0.0
var _snags: Array = []
var _snag := false
var _snag_still := 0.0
var _moved := false
var _twist := 0.0          # faza 2: ture răsucite
var _twist_ang := 0.0      # unghiul cleștelui, pentru desen
var _bend := 0.0           # faza 3: 0 = codița în afară, 1 = îndoită
var _bend_start := Vector2.ZERO
var _busy := false         # o replică e pe ecran
var _hint: Label
var _tip: Label
var _pliers: TextureRect


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
	_pliers = TextureRect.new()
	_pliers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pliers.visible = false
	if ResourceLoader.exists("res://art/final/mana_cleste_zavor.png"):
		_pliers.texture = load("res://art/final/mana_cleste_zavor.png")
	_root.add_child(_pliers)
	_tip = _label(Vector2(0, 8), Color(1, 1, 1, 0.75))
	_hint = _label(Vector2(0, Game.H - 34), Color(1, 0.9, 0.7, 0.9))
	_set_tip()
	_finger = center + Vector2(40, 30)
	_new_snags()


func _label(pos: Vector2, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(Game.W, 24)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(l)
	return l


func _set_tip() -> void:
	_tip.text = ["", "Trage în cerc, în jurul zăvorului", "Învârte cleștele: răsucește capetele, apoi dă-i drumul", "Trage codița în jos, lipită de plăcuță"][_phase]


func _new_snags() -> void:
	_snags = [randf_range(1.0, 2.0), randf_range(2.6, 3.6), randf_range(4.0, 4.7)]


func _on_input(e: InputEvent) -> void:
	if _done or _busy:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_dragging = e.pressed
		if e.pressed:
			_finger = e.position
			_last_ang = (e.position - center).angle()
			_bend_start = e.position
		elif _phase == 2 and _twist > 0.3:
			_release_twist()
	elif e is InputEventMouseMotion and _dragging:
		_finger = e.position
		var ang: float = (e.position - center).angle()
		var dlt := wrapf(ang - _last_ang, -PI, PI)
		_last_ang = ang
		var r: float = (e.position - center).length()
		if _phase == 1 and r > 22.0 and r < 110.0:
			if not _snag:
				_progress += absf(dlt) / TAU
			_speed += absf(dlt)
			_idle = 0.0
			if absf(dlt) > 0.004:
				_moved = true
		elif _phase == 2 and r > 14.0:
			_twist += absf(dlt) / TAU
			_twist_ang += dlt
			_speed += absf(dlt)
		elif _phase == 3:
			_bend = clampf((e.position.y - _bend_start.y) / 40.0, _bend, 1.0)
			if _bend >= 1.0:
				_finish()


func _process(d: float) -> void:
	if _done:
		return
	_ang_v = lerpf(_ang_v, _speed / maxf(d, 0.001), clampf(d * 8.0, 0.0, 1.0))
	_speed = 0.0
	if OS.has_feature("web"):   # pentru testele automate din browser
		JavaScriptBridge.eval("window.latch={p:%f,snag:%s,phase:%d,tw:%f}" % [_progress, "true" if _snag else "false", _phase, _twist])
	if _busy:
		_draw.queue_redraw()
		return
	if _phase == 1:
		_process_wrap(d)
	elif _phase == 2:
		_process_twist(d)
	_snap_flash = maxf(0.0, _snap_flash - d)
	_update_pliers()
	_draw.queue_redraw()


func _process_wrap(d: float) -> void:
	var limit := lerpf(8.0, 2.8, clampf(_progress / TURNS, 0.0, 1.0))
	var target := _ang_v / limit
	if not _snags.is_empty() and _progress >= _snags[0] and not _snag:
		_snag = true
		_snag_still = 0.0
		_hint.text = "S-a agățat în rugină... stai o clipă."
	if _snag:
		if _ang_v > 0.5:
			target = 0.6 + _ang_v / limit * 3.0
			_snag_still = 0.0
		else:
			_snag_still += d
			if _snag_still > 0.5:
				_snag = false
				_snags.pop_front()
				_hint.text = ""
	_moved = false
	_tension = lerpf(_tension, clampf(target, 0.0, 1.6), clampf(d * 10.0, 0.0, 1.0))
	if _tension > 1.0:
		_over_t += d
		if _over_t > (0.55 if _snag else 0.18):
			_snap("wrap")
	else:
		_over_t = 0.0
	_idle += d
	if not _snag and _progress > 0.0 and (_idle > 0.35 or (_dragging and _ang_v < 1.0)):
		_progress = maxf(0.0, _progress - d * (0.9 if _idle > 0.35 else 0.35))
		_tension = maxf(0.0, _tension - d)
	if _progress >= TURNS:
		_progress = TURNS
		_next_phase(2, "Gata înfășurat. Acu' prind capetele cu cleștele și le răsucesc. Nu prea mult, că sârma se-ntărește și crapă.")


func _process_twist(_d: float) -> void:
	# sârma se întărește la răsucit: peste măsură crapă
	_tension = clampf(_twist / TWIST_MAX, 0.0, 1.2)
	if _twist > TWIST_MAX:
		_snap("twist")


func _release_twist() -> void:
	if _twist < TWIST_OK:
		_say_async("Încă e moale. Mai răsucesc.")
		return
	_next_phase(3, "Ține. Acu' îndoi codița, s-o lipesc de plăcuță.")


func _next_phase(p: int, line: String) -> void:
	_phase = p
	_dragging = false
	_hint.text = ""
	_set_tip()
	_pliers.visible = p == 2
	_say_async(line)


func _say_async(line: String) -> void:
	_busy = true
	await Game.say("Romică", line)
	_busy = false


func _finish() -> void:
	_done = true
	_dragging = false
	_tip.text = ""
	_draw.queue_redraw()
	await get_tree().create_timer(0.6).timeout
	finished.emit("ok")


func _snap(kind: String) -> void:
	_tension = 0.0
	_over_t = 0.0
	_dragging = false
	_snag = false
	_hint.text = ""
	_snap_flash = 0.4
	Game.shake(3.0, 0.25)
	var lines: Array
	if kind == "wrap":
		_progress = 0.0
		_new_snags()
		lines = ["Pac! Se rupse. Fir-ar mama ei de sârmă.", "Iar se rupse... Mai domol, Romică, că nu-i frâna de la tractor.", "Sârma vrea răbdare, nu putere.", "Futu-i... De la capăt."]
	else:
		_twist = 0.0
		lines = ["Crăpă la răsucit. Prea mult, Romică. Taie capătu' și mai încearcă.", "Iar o răsucii peste. Când se strânge, îi dai drumu'!"]
	_say_async(lines.pick_random())


func _update_pliers() -> void:
	if not _pliers.visible:
		return
	var tip := _pig_end()
	if _pliers.texture:
		var sz := _pliers.texture.get_size()
		_pliers.pivot_offset = Vector2(0, sz.y * 0.45)
		_pliers.position = tip - _pliers.pivot_offset
		_pliers.rotation = sin(_twist_ang) * 0.25 + 0.35


# ---------------------------------------------------------------- desen

func _coil_x(k: float) -> float:
	return lerpf(coil_x.x, coil_x.y, k / maxf(TURNS, 1.0))


func _pig_start() -> Vector2:
	return hole + Vector2(10, 6)


func _pig_end() -> Vector2:
	var length := 6.0 + minf(_twist, TWIST_MAX) * 2.4
	var dir := Vector2(1, 0.55).normalized().lerp(Vector2(-0.2, 1), _bend).normalized()
	return _pig_start() + dir * length


func _on_draw() -> void:
	var n := int(floor(_progress))
	var frac := _progress - n
	# turele: fiecare trece prin gaura plăcuței, urcă peste bară și coboară înapoi
	for k in n:
		_coil(_coil_x(k), 1.0)
	if _phase == 1 and frac > 0.0:
		_coil(_coil_x(n), frac)
	# capetele: din prima și din ultima tură spre locul unde se răsucesc
	var a := Vector2(_coil_x(0), hole.y + 2)
	var b := Vector2(_coil_x(maxf(n - 1, 0)) + 2, hole.y + 3)
	var s := _pig_start()
	if _phase >= 2 or _done:
		_wire([a, (a + s) / 2 + Vector2(0, 4), s], COPPER)
		_wire([b, (b + s) / 2 + Vector2(0, 2), s], COPPER.darkened(0.15))
		_pigtail(s, _pig_end())
	elif _phase == 1:
		# capătul liber, tras cu mâna: întins când e strâns, lăsat în jos când e moale
		var start := Vector2(_coil_x(n) + 2, hole.y + 2)
		var tight := clampf(_tension, 0.0, 1.0)
		var mid := (start + _finger) / 2.0 + Vector2(0, (1.0 - tight) * 28.0)
		var col := COPPER.lerp(Color(1.0, 0.95, 0.75), clampf((_tension - 0.6) * 2.0, 0.0, 1.0))
		_wire([start, mid, _finger], col)
		_wire([a, a + Vector2(-6, 14), a + Vector2(-4, 26)], COPPER.darkened(0.1))   # celălalt capăt, atârnă
		if _snag:
			_draw.draw_polyline(PackedVector2Array([start.round(), (start + Vector2(4, -3)).round(), (start + Vector2(7, 2)).round()]), COPPER.darkened(0.2), 2.0)
		if _tension > 0.85:
			_draw.draw_circle(start, 2.0 + randf() * 1.5, Color(1, 1, 0.8, 0.5))
	if _phase == 2 and not _pliers.texture:   # schiță de clește până vine desenul
		var e := _pig_end()
		var dir := Vector2.from_angle(sin(_twist_ang) * 0.25 + 0.35)
		_draw.draw_line(e, e + dir * 70 + Vector2(0, -6), Color(0.6, 0.15, 0.12), 6.0)
		_draw.draw_line(e, e + dir * 70 + Vector2(0, 8), Color(0.6, 0.15, 0.12), 6.0)
		_draw.draw_circle(e + dir * 6, 5, Color(0.45, 0.45, 0.5))
	if _snap_flash > 0.0:
		_draw.draw_rect(Rect2(Vector2.ZERO, _draw.size), Color(1, 1, 1, _snap_flash * 0.5))
	if _done:
		_draw.draw_rect(Rect2(Vector2.ZERO, _draw.size), Color(0, 0, 0, 0.25))


## O tură: din gaură în sus pe fața plăcuței, peste bară (partea din spate nu se vede), înapoi în gaură.
func _coil(x: float, amount: float) -> void:
	var bot := Vector2(x, hole.y)
	var top := Vector2(x + 2, bar_top)
	var pts := PackedVector2Array()
	var steps := 10
	for i in steps + 1:
		var t := i / float(steps) * amount
		var p := bot.lerp(top, t)
		p.x += sin(t * PI) * 3.0   # se mulează pe plăcuță și pe bară
		pts.append(p.round())
	_draw.draw_polyline(pts, Color(0, 0, 0, 0.35), 4.0)
	_draw.draw_polyline(pts, COPPER, 2.0)
	if pts.size() > 3:
		_draw.draw_polyline(PackedVector2Array([pts[1] + Vector2(-1, 0), pts[pts.size() / 2] + Vector2(-1, 0)]), COPPER_HI, 1.0)
	if amount >= 1.0:   # peste bară se vede un mic arc, apoi coboară pe spate
		_draw.draw_line(top.round(), (top + Vector2(2, -2)).round(), COPPER_LO, 2.0)


func _wire(p: Array, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		pts.append(((1 - t) * (1 - t) * p[0] + 2 * (1 - t) * t * p[1] + t * t * p[2]).round())
	_draw.draw_polyline(pts, Color(0, 0, 0, 0.35), 4.0)
	_draw.draw_polyline(pts, col, 2.0)
	_draw.draw_polyline(pts, Color(col.lightened(0.3), 0.6), 1.0)


## Codița răsucită: două fire împletite; cu cât e mai răsucită, cu atât pasul e mai mic și arama mai deschisă (întărită).
func _pigtail(s: Vector2, e: Vector2) -> void:
	var ln := s.distance_to(e)
	var dir := (e - s).normalized()
	var nrm := Vector2(-dir.y, dir.x)
	var pitch := lerpf(7.0, 2.5, clampf(_twist / TWIST_MAX, 0.0, 1.0))
	var hard := clampf((_twist - TWIST_OK) / (TWIST_MAX - TWIST_OK), 0.0, 1.0)
	var c1 := COPPER.lerp(Color(1.0, 0.9, 0.7), hard * 0.6)
	var c2 := c1.darkened(0.3)
	var pa := PackedVector2Array()
	var pb := PackedVector2Array()
	var steps := int(ln) + 1
	for i in steps + 1:
		var t := i / float(steps) * ln
		var w := sin(t / pitch * TAU + _twist_ang) * 1.5
		pa.append((s + dir * t + nrm * w).round())
		pb.append((s + dir * t - nrm * w).round())
	_draw.draw_polyline(pa, Color(0, 0, 0, 0.35), 4.0)
	_draw.draw_polyline(pb, c2, 2.0)
	_draw.draw_polyline(pa, c1, 2.0)
