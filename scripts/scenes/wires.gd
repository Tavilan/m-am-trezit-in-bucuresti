extends GameScene
## 5. Minigame: „repararea” frigiderului de bere (tutorialul).
## Tragi cu degetul/mouse-ul de la fiecare fir al frigiderului la o bornă.
## Orice ai lega, Romică mai adaugă „un fir la stâlp, să răcească mai tare” — și ia foc.

const WIRES := [["roșu", Color("#d84a3a")], ["albastru", Color("#4a7ad8")], ["galben-verde", Color("#c8c83a")]]
const TERMINALS := ["FAZĂ", "NUL", "PĂMÂNT", "STÂLPUL DE CURENT"]

var _from := []        # pozițiile firelor
var _to := []          # pozițiile bornelor
var _links := {}       # fir -> bornă
var _drag := -1
var _mouse := Vector2.ZERO
var _sparks := 0.0
var _done := false


func _ready() -> void:
	title = "Frigiderul de bere"
	bg_color = Color("#1a1612")
	for i in WIRES.size():
		_from.append(Vector2(150, 110 + i * 60))
	for j in TERMINALS.size():
		_to.append(Vector2(440, 100 + j * 52))


func enter() -> void:
	await say("Romică", "Ia să vedem... Trei fire. Patru borne. Floare la ureche.")
	await say("", "Trage cu degetul de la fiecare fir al frigiderului la o bornă.")


func _input(e: InputEvent) -> void:
	if _done or Game.busy:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = get_global_mouse_position()
		if e.pressed:
			for i in _from.size():
				if p.distance_to(_from[i]) < 22:
					_drag = i
					_mouse = p
		elif _drag >= 0:
			for j in _to.size():
				if p.distance_to(_to[j]) < 26:
					_links[_drag] = j
			_drag = -1
			queue_redraw()
			if _links.size() == WIRES.size():
				_done = true
				Game.interact(_finish)
	elif e is InputEventMouseMotion and _drag >= 0:
		_mouse = get_global_mouse_position()
		queue_redraw()


func _finish() -> void:
	var correct: bool = _links.get(0) == 0 and _links.get(1) == 1 and _links.get(2) == 2
	if correct:
		await say("Romică", "Fază la fază, nul la nul, pământ la pământ. Ca la carte!")
		await say("Romică", "Da' ca să răcească ca-n Germania... mai pun un fir. La stâlp.")
	else:
		await say("Romică", "Hmm. Nu știu dacă așa se leagă... Da' merge și-așa. Mai pun un fir la stâlp, de siguranță.")
	_links[3] = 3
	set_process(true)
	_sparks = 2.2
	await Game.shake(4.0, 1.2)
	await Game.flash(Color("#ffb040"), 1.0)
	Game.flags["fire"] = true
	Game.goto("pub", 0.2)


func _process(d: float) -> void:
	if _sparks > 0.0:
		_sparks -= d
		queue_redraw()


func _draw() -> void:
	super._draw()
	draw_rect(Rect2(130, 60, 60, 230), Color("#b8c0c4"))
	draw_string(Game.font, Vector2(20, 80), "FRIGIDER BERE", HORIZONTAL_ALIGNMENT_LEFT, 160, Game.FS, Color("#ddd"))
	draw_rect(Rect2(420, 60, 210, 230), Color("#3a3428"))
	draw_string(Game.font, Vector2(424, 80), "TABLOU", HORIZONTAL_ALIGNMENT_LEFT, 166, Game.FS, Color("#ddd"))
	for i in _from.size():
		draw_circle(_from[i], 9, WIRES[i][1])
		draw_string(Game.font, _from[i] + Vector2(-140, 5), WIRES[i][0], HORIZONTAL_ALIGNMENT_RIGHT, 125, Game.FS, Color.WHITE)
	for j in _to.size():
		draw_circle(_to[j], 9, Color("#c8a040") if j < 3 else Color("#d84040"))
		draw_string(Game.font, _to[j] + Vector2(14, 5), TERMINALS[j], HORIZONTAL_ALIGNMENT_LEFT, 190, Game.FS, Color.WHITE)
	for i in _links:
		var start: Vector2 = _from[i] if i < _from.size() else Vector2(190, 280)
		var col: Color = WIRES[i][1] if i < WIRES.size() else Color("#b07a3a")
		_wire(start, _to[_links[i]], col)
	if _drag >= 0:
		_wire(_from[_drag], _mouse, WIRES[_drag][1])
	if _sparks > 0.0:
		for k in 30:
			var c := Vector2(randf_range(300, 600), randf_range(60, 300))
			draw_rect(Rect2(c, Vector2(3, 3)), Color(1, 0.9, 0.4))


func _wire(a: Vector2, b: Vector2, c: Color) -> void:
	var mid := (a + b) / 2 + Vector2(0, 30)
	var pts := PackedVector2Array()
	for t in 17:
		var u := t / 16.0
		pts.append(a.lerp(mid, u).lerp(mid.lerp(b, u), u))
	draw_polyline(pts, c, 3.0)
