extends GameScene
## 5. Minigame: „repararea” frigiderului de bere (demonstrația pentru Marius).
## Tragi cu degetul fiecare fir al frigiderului la o bornă din doza de pe perete.
## Legat greșit: te curentează (comic) și o iei de la capăt. Culorile sunt cele adevărate:
## maro = fază (L), albastru = nul (N), galben-verde = împământare (PE).
## Legat corect: Romică, din mândrie, mai trage „un fir de la stâlp, să răcească ca-n Germania” — și ia foc.

const ART := "res://art/final/frigider_spate.png"
const WIRES := [["maro", Color("#7a4a2a")], ["albastru", Color("#3a6ad8")], ["galben-verde", Color("#b8c83a")]]
const LABELS := ["L", "N", "PE", "STÂLP"]

var _from := []        # capetele firelor
var _to := []          # bornele
var _links := {}       # fir -> bornă
var _drag := -1
var _mouse := Vector2.ZERO
var _sparks := 0.0
var _done := false
var _shocks := 0
var _art := false


func _ready() -> void:
	title = "Frigiderul de bere"
	music = "res://audio/manele_tv.ogg"
	radio = true
	_art = ResourceLoader.exists(ART)
	if _art:
		background(ART)
	else:
		bg_color = Color("#1a1612")
	var j := {}
	var jp := ART.replace(".png", ".json")
	if FileAccess.file_exists(jp):
		j = JSON.parse_string(FileAccess.open(jp, FileAccess.READ).get_as_text())
	var f: Array = j.get("wires", [[300, 170], [300, 210], [300, 250]])
	var t: Array = j.get("terminals", [[440, 120], [440, 172], [440, 224], [440, 276]])
	for p in f:
		_from.append(Vector2(p[0], p[1]))
	for p in t:
		_to.append(Vector2(p[0], p[1]))


func enter() -> void:
	await say("Romică", "Ia să vedem... Trei fire, patru borne. Floare la ureche.")
	await say("Marius", "Maro e faza, unchiule. Ca să știi.")
	await say("Romică", "Știu, mă, că io te-am învățat!")
	await say("", "Trage fiecare fir al frigiderului la borna lui.")


func _input(e: InputEvent) -> void:
	if _done or Game.busy:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = get_global_mouse_position()
		if e.pressed:
			for i in _from.size():
				if p.distance_to(_from[i]) < 18:
					_drag = i
					_links.erase(i)
					_mouse = p
		elif _drag >= 0:
			for j in 3:   # borna de la stâlp n-o legi tu; o leagă Romică singur, la final
				if p.distance_to(_to[j]) < 18 and not _links.values().has(j):
					_links[_drag] = j
			_drag = -1
			queue_redraw()
			if _links.size() == WIRES.size():
				Game.interact(_check)
	elif e is InputEventMouseMotion and _drag >= 0:
		_mouse = get_global_mouse_position()
		queue_redraw()


func _check() -> void:
	var correct: bool = _links.get(0) == 0 and _links.get(1) == 1 and _links.get(2) == 2
	if not correct:
		_shocks += 1
		_sparks = 0.4
		set_process(true)
		Game.shake(5.0, 0.3)
		await Game.flash(Color("#e8f0ff"), 0.3)
		var lines := [
			["Romică", "Auuu! Mă curentă, fir-ar mama ei!"],
			["Marius", "Maro e faza, unchiule. Ți-am zis."],
			["Romică", "Futu-i... Nu-i nimic, așa verific io dacă e curent."],
			["Nelu", "Iar l-a curentat!"],
		]
		var l: Array = lines[(_shocks - 1) % lines.size()]
		await say(l[0], l[1])
		_links.clear()
		queue_redraw()
		return
	_done = true
	await say("Romică", "Fază la fază, nul la nul, pământ la pământ. Ca la carte, mă!")
	await say("Marius", "Bravo, unchiule. Asta știe orice ucenic în Germania.")
	await say("Romică", "Orice ucenic, ziseși? Da' ca să răcească ca-n Germania... mai trag un fir. Direct de la stâlp.")
	await say("Marius", "Unchiule, nu! Ăla-i...")
	_links[3] = 3
	queue_redraw()
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
	if not _art:
		draw_rect(Rect2(250, 140, 70, 140), Color("#b8c0c4"))
		draw_rect(Rect2(420, 90, 90, 210), Color("#4a4a48"))
	for i in _from.size():
		draw_circle(_from[i], 5, WIRES[i][1])
		draw_circle(_from[i], 5, Color(0, 0, 0, 0.6), false, 1.0)
	for j in _to.size():
		draw_circle(_to[j], 4, Color("#c8a040") if j < 3 else Color("#8a6a4a"))
		draw_string(Game.font, _to[j] + Vector2(9, 5), LABELS[j], HORIZONTAL_ALIGNMENT_LEFT, 60, Game.FS, Color(1, 1, 1, 0.8))
	for i in _links:
		var start: Vector2 = _from[i] if i < _from.size() else Vector2(_to[3].x + 60, 0)
		var col: Color = WIRES[i][1] if i < WIRES.size() else Color("#b07a3a")
		_wire(start, _to[_links[i]], col)
	if _drag >= 0:
		_wire(_from[_drag], _mouse, WIRES[_drag][1])
	if _sparks > 0.0:
		for k in 24:
			var c: Vector2 = _to[randi() % _to.size()] + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			draw_rect(Rect2(c.round(), Vector2(2, 2)), Color(1, 0.95, 0.6))


func _wire(a: Vector2, b: Vector2, c: Color) -> void:
	var mid := (a + b) / 2 + Vector2(0, 24)
	var pts := PackedVector2Array()
	for t in 17:
		var u := t / 16.0
		pts.append(a.lerp(mid, u).lerp(mid.lerp(b, u), u).round())
	draw_polyline(pts, c.darkened(0.4), 4.0)
	draw_polyline(pts, c, 2.0)
