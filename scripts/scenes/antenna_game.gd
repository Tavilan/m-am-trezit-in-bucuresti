extends CanvasLayer
## Minijocul cu antena de cameră a televizorului din birt.
## Tragi antena pe perete până prinde imaginea. Ca în viața reală: cât o ții în mână, prinde mai bine
## (corpul tău e și el antenă); când îi dai drumul, purecii revin. Trebuie găsit locul unde prinde și singură
## (lângă un cui, unde o legi cu sârmă), apoi o lași acolo și aștepți să se vadă curat.

signal finished(result: String)

const ART := "res://art/final/televizor_perete.png"
var screen := Rect2(92, 74, 176, 132)   # ecranul televizorului (se reglează după desen, din .json)
var area := Rect2(250, 20, 380, 250)    # unde poți pune antena pe perete
var sweet := Vector2(470, 70)           # locul bun (lângă un cui); se reglează din .json
var nails: Array = [Vector2(470, 70), Vector2(560, 120), Vector2(390, 150)]
const RADIUS := 26.0                    # cât de larg e locul bun, în pixeli
const HAND := 0.35                      # cât ajută mâna ta pe antenă
const HOLD := 1.6                       # cât trebuie să țină curat imaginea, lăsată singură

var _root: Control
var _draw: Control
var _ant: TextureRect
var _ant_pos := Vector2(330, 200)
var _holding := false
var _grab := Vector2.ZERO
var _q := 0.0          # cât de bine prinde acum (0..1)
var _shown := 0.0      # cât de curată e imaginea (urmează _q, cu întârziere)
var _clean_t := 0.0
var _done := false
var _snow: Array = []  # câteva texturi de purici, schimbate repede
var _snow_i := 0
var _snow_t := 0.0
var _picture: Texture2D
var _t := 0.0
var _drift := Vector2.ZERO


func _ready() -> void:
	layer = 5
	_root = Control.new()
	_root.size = Vector2(Game.W, Game.H)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(_on_input)
	add_child(_root)
	if ResourceLoader.exists(ART):
		var bg := TextureRect.new()
		bg.texture = load(ART)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(bg)
		var jp := ART.replace(".png", ".json")
		if ResourceLoader.exists(jp) or FileAccess.file_exists(jp):
			var j: Dictionary = JSON.parse_string(FileAccess.open(jp, FileAccess.READ).get_as_text())
			screen = Rect2(j["screen"][0], j["screen"][1], j["screen"][2], j["screen"][3])
			area = Rect2(j["area"][0], j["area"][1], j["area"][2], j["area"][3])
			nails = []
			for n in j["nails"]:
				nails.append(Vector2(n[0], n[1]))
	else:
		var ph := ColorRect.new()
		ph.color = Color("#3a3830")
		ph.size = _root.size
		ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(ph)
	# locul bun e la unul dintre cuie, altul de fiecare dată
	sweet = nails.pick_random() + Vector2(0, 14)
	if ResourceLoader.exists("res://art/final/tv_ecran_mic.png"):
		_picture = load("res://art/final/tv_ecran_mic.png")
	for k in 6:
		var img := Image.create(int(screen.size.x / 2), int(screen.size.y / 2), false, Image.FORMAT_RGBA8)
		for y in img.get_height():
			for x in img.get_width():
				var v := randf()
				img.set_pixel(x, y, Color(v, v, v, 1.0))
		_snow.append(ImageTexture.create_from_image(img))
	_draw = Control.new()
	_draw.size = _root.size
	_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw.draw.connect(_on_draw)
	_root.add_child(_draw)
	_ant = TextureRect.new()
	_ant.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://art/final/antena_camera_perete.png"):
		_ant.texture = load("res://art/final/antena_camera_perete.png")
	_root.add_child(_ant)
	var tip := Label.new()
	tip.text = "Mută antena pe perete până prinde. Las-o din mână să vezi dacă ține."
	tip.position = Vector2(0, Game.H - 30)
	tip.size = Vector2(Game.W, 24)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	tip.add_theme_color_override("font_shadow_color", Color.BLACK)
	tip.add_theme_constant_override("shadow_offset_y", 1)
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(tip)


func _ant_size() -> Vector2:
	return _ant.texture.get_size() if _ant.texture else Vector2(30, 40)


func _on_input(e: InputEvent) -> void:
	if _done:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			var r := Rect2(_ant_pos - Vector2(_ant_size().x / 2.0, _ant_size().y), _ant_size()).grow(14)
			if r.has_point(e.position):
				_holding = true
				_grab = _ant_pos - e.position
		else:
			_holding = false
	elif e is InputEventMouseMotion and _holding:
		var p: Vector2 = e.position + _grab
		_ant_pos = Vector2(clampf(p.x, area.position.x, area.end.x), clampf(p.y, area.position.y, area.end.y))


func _process(d: float) -> void:
	_t += d
	if _done:
		_draw.queue_redraw()
		return
	# semnalul „plutește” puțin (vremea, ploaia), ca să nu fie un singur pixel magic
	_drift = Vector2(sin(_t * 0.7), cos(_t * 0.5)) * 5.0
	var dist := _ant_pos.distance_to(sweet + _drift)
	var q := exp(-pow(dist / RADIUS, 2.0))
	if _holding:
		q = minf(1.0, q + HAND * (0.4 + 0.6 * q))
	_q = q
	if OS.has_feature("web"):   # pentru testele automate din browser
		JavaScriptBridge.eval("window.ant={q:%f,sx:%f,sy:%f,ax:%f,ay:%f}" % [q, sweet.x, sweet.y, _ant_pos.x, _ant_pos.y])
	_shown = lerpf(_shown, _q, clampf(d * 3.0, 0.0, 1.0))
	# sunetul: manelele urcă, purecii scad
	Game.mix(lerpf(-34.0, -8.0, _shown), lerpf(-8.0, -40.0, _shown))
	if not _holding and _q > 0.8:
		_clean_t += d
		if _clean_t > HOLD:
			_win()
	else:
		_clean_t = 0.0
	_snow_t += d
	if _snow_t > 0.05:
		_snow_t = 0.0
		_snow_i = (_snow_i + 1) % _snow.size()
	_ant.position = (_ant_pos - Vector2(_ant_size().x / 2.0, _ant_size().y)).round()
	_draw.queue_redraw()


func _win() -> void:
	_done = true
	_shown = 1.0
	Game.mix(-8.0, -60.0)
	await get_tree().create_timer(0.8).timeout
	finished.emit("ok")


func _on_draw() -> void:
	var clean := clampf(_shown, 0.0, 1.0)
	# imaginea (manelele), întunecată și tremurată când prinde prost
	if _picture:
		var jitter := Vector2(randf_range(-1, 1) * (1.0 - clean) * 3.0, 0).round()
		_draw.draw_texture_rect(_picture, Rect2(screen.position + jitter, screen.size), false, Color(1, 1, 1, 0.25 + 0.75 * clean))
	else:
		_draw.draw_rect(screen, Color(0.5, 0.3, 0.6, 0.25 + 0.75 * clean))
	# purecii
	_draw.draw_texture_rect(_snow[_snow_i], screen, false, Color(1, 1, 1, clampf(1.0 - clean * 1.15, 0.0, 0.95)))
	# dunga care urcă pe ecran când semnalul e slab
	if clean < 0.7:
		var y := screen.position.y + fposmod(_t * 40.0, screen.size.y)
		_draw.draw_rect(Rect2(screen.position.x, y, screen.size.x, 3), Color(1, 1, 1, 0.18 * (1.0 - clean)))
	# cablul antenei: de la spatele televizorului până la antenă, lăsat moale
	var a := Vector2(screen.end.x + 6, screen.position.y + 20)
	var b := _ant_pos + Vector2(0, -2)
	var mid := (a + b) / 2.0 + Vector2(0, 30)
	var pts := PackedVector2Array()
	for k in 15:
		var u := k / 14.0
		pts.append(a.lerp(mid, u).lerp(mid.lerp(b, u), u).round())
	_draw.draw_polyline(pts, Color(0.35, 0.25, 0.18), 2.0)
	if not _ant.texture:   # până vine desenul antenei: o schiță
		_draw.draw_line(_ant_pos, _ant_pos + Vector2(-14, -38), Color(0.8, 0.8, 0.85), 2.0)
		_draw.draw_line(_ant_pos, _ant_pos + Vector2(14, -38), Color(0.8, 0.8, 0.85), 2.0)
		_draw.draw_rect(Rect2(_ant_pos - Vector2(8, 4), Vector2(16, 6)), Color(0.1, 0.1, 0.1))
