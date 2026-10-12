extends GameScene
## 2. Drumul prin sat, noaptea, pe ploaie. Birtul Unirea luminat la capătul drumului.
## Artă: fundal + câinele lui Ilie (strat separat); ploaia, băltoacele, felinarul și vitrina sunt animate din cod.

const LAMP := Vector2(170, 22)            # becul felinarului de pe stâlp
const PUB_WINDOW := Rect2(452, 170, 66, 36)
const PUDDLES := [Vector2(150, 330), Vector2(250, 290), Vector2(440, 305), Vector2(520, 300), Vector2(590, 340), Vector2(300, 345)]

var _t := 0.0
var _rain: Array = []      # stropi în aer: [poziție, strat, y unde lovesc pământul]
var _splash: Array = []    # stropi care se sparg pe jos: [poziție, vârstă]
## trei straturi de adâncime: departe (mici, lenți, slabi) -> aproape (lungi, rapizi)
const RAIN_LAYERS := [
	{"n": 170, "speed": 300.0, "len": 3.0, "alpha": 0.32},
	{"n": 90, "speed": 440.0, "len": 6.0, "alpha": 0.45},
	{"n": 34, "speed": 640.0, "len": 11.0, "alpha": 0.55},
]
const WIND := -0.12        # vântul înclină puțin ploaia spre stânga
## surse care luminează stropii (în afară de felinar): vitrina birtului și felinarele din depărtare
const GLOWS := [[Vector2(485, 188), 70.0, 0.5], [Vector2(298, 126), 30.0, 0.35], [Vector2(316, 160), 18.0, 0.25]]
var _ripples: Array = []   # [poziție, vârstă]
var _lamp_on := 1.0       # 0 = stins, 1 = aprins (trecerea e o clipă, ca la un bec real)
var _lamp_target := 1.0
var _curve: Array = []      # intensitatea felinarului, cadru cu cadru, din video-ul Veo
var _curve_fps := 24.0
var _curve_t := 0.0
var _hold := 2.0
var _lamp_mat: ShaderMaterial
var _hum := 0.0
var _over: Node2D
var _dog_sprite: AnimSprite
var _ilie: Sprite2D
## pietrele peste băltoaca dinspre birt: [centru, lățime, fază]; se scufundă și ies pe rând (apa crește de la ploaie)
var _stones: Array = []
var _stone_i := 0          # următoarea piatră pe care trebuie să calci
var _crossing := false     # minijocul e pornit
var _splashes: Array = []  # [poziție, vârstă, mare]
const STONE_PATH := [Vector2(300, 350), Vector2(336, 318), Vector2(372, 293), Vector2(410, 272), Vector2(448, 254), Vector2(486, 238)]


func _ready() -> void:
	title = "Drumul prin sat, noaptea"
	horizon = 200   # punctul de fugă al drumului
	# lumina: noapte albastră, felinarul (portocaliu) și vitrina birtului (caldă)
	lighting = {"ambient": Vector3(0.7, 0.72, 0.9), "saturation": 0.9,
		"light1_pos": LAMP, "light1_color": Vector3(1.0, 0.7, 0.35), "light1_radius": 400.0, "light1_strength": 0.9,
		"light2_pos": Vector2(485, 190), "light2_color": Vector3(1.0, 0.8, 0.45), "light2_radius": 120.0, "light2_strength": 0.3}
	grade = {"tint": Vector3(0.66, 0.66, 0.8), "saturation": 0.68}
	ambience = "res://audio/ploaie_afara.ogg"
	background("res://art/final/drum_fundal.png")
	# fundalul = varianta stinsă + lumina felinarului înmulțită cu intensitatea (shaders/light_mix.gdshader)
	_lamp_mat = ShaderMaterial.new()
	_lamp_mat.shader = preload("res://shaders/light_mix.gdshader")
	_lamp_mat.set_shader_parameter("off_tex", load("res://art/final/drum_fundal_felinar_stins.png"))
	_bg.material = _lamp_mat
	var cf := FileAccess.open("res://art/anim/felinar/curve.json", FileAccess.READ)
	if cf:
		var j: Dictionary = JSON.parse_string(cf.get_as_text())
		_curve = j.get("intensity", [])
		_curve_fps = float(j.get("fps", 24))
	# câinele lui Ilie stă ghemuit la uscat sub banca de la poartă (sub streașină) și tremură de frig
	var dog := anim("caine_tremura_mic", Vector2(84, 263))
	_dog_sprite = dog
	# sub bancă e umbră: câinele trăiește aproape numai din lumina felinarului
	var dm := dog.material as ShaderMaterial
	dm.set_shader_parameter("ambient", Vector3(0.38, 0.4, 0.58))
	_over = Node2D.new()
	_over.draw.connect(_draw_over)
	add_child(_over)
	for li in RAIN_LAYERS.size():
		for i in RAIN_LAYERS[li]["n"]:
			_rain.append(_new_drop(li, randf_range(-20, Game.H)))
	hotspot("Felinarul", Rect2(104, 0, 40, 265), _lamp)
	hotspot("Câinele lui Ilie", Rect2(46, 214, 76, 52), _dog)
	hotspot("Birtul Unirea", Rect2(412, 120, 140, 92), _pub)
	hotspot("Poarta lui Nea Ilie", Rect2(137, 165, 60, 85), _gate)
	# Nea Ilie apare la poartă după ce îl strigi (dacă arta lui e gata)
	if ResourceLoader.exists("res://art/final/ilie_drum.png"):
		_ilie = layer("res://art/final/ilie_drum.png", Vector2(168, 252))
		figure(_ilie, "Nea Ilie")
		_ilie.visible = false
	for k in STONE_PATH.size():
		var c: Vector2 = STONE_PATH[k]
		var w: float = (c.y - horizon) * 0.2
		_stones.append([c, w, randf_range(0, TAU)])
		hotspot("Piatra", Rect2(c - Vector2(w * 0.8, w * 0.45), Vector2(w * 1.6, w * 0.9)), _stone.bind(k))


func enter() -> void:
	await say("Romică", "Ce noapte frumoasă... Și ce ceartă urâtă.")


func _process(d: float) -> void:
	_t += d
	for dr in _rain:
		var L: Dictionary = RAIN_LAYERS[dr[1]]
		dr[0] += Vector2(WIND, 1.0) * L["speed"] * d
		if dr[0].y >= dr[2]:
			if dr[1] == 2:   # stropii din față se sparg pe drum
				_splash.append([Vector2(dr[0].x, dr[2]).round(), 0.0])
			var nd := _new_drop(dr[1], randf_range(-30, -5))
			dr[0] = nd[0]
			dr[2] = nd[2]
	for sp in _splash:
		sp[1] += d
	_splash = _splash.filter(func(sp): return sp[1] < 0.14)
	if randf() < d * 6.0:
		_ripples.append([PUDDLES[randi() % PUDDLES.size()] + Vector2(randf_range(-20, 20), randf_range(-4, 4)), 0.0])
	for r in _ripples:
		r[1] += d
	_ripples = _ripples.filter(func(r): return r[1] < 0.8)
	_update_lamp(d)
	_lamp_mat.set_shader_parameter("intensity", _lamp_on)
	(_dog_sprite.material as ShaderMaterial).set_shader_parameter("light1_strength", 1.3 * _lamp_on)
	for sp in _splashes:
		sp[1] += d
	_splashes = _splashes.filter(func(sp): return sp[1] < 0.5)
	_over.queue_redraw()


func _stone_up(k: int) -> float:
	# >0 = piatra e deasupra apei; ritmuri diferite, ca să trebuiască să alegi momentul
	var st: Array = _stones[k]
	return sin(_t * (0.9 + 0.17 * k) + st[2])


func _draw_stones() -> void:
	for k in _stones.size():
		var c: Vector2 = _stones[k][0]
		var w: float = _stones[k][1]
		var up := _stone_up(k)
		var lit := clampf(_light_at(c) * 1.4, 0.0, 1.0)
		if up > -0.15:
			var h: float = clampf(up + 0.15, 0.0, 1.0)
			var stone := Color(0.24, 0.23, 0.24).lerp(Color(0.5, 0.38, 0.25), lit * 0.6)
			_over.draw_set_transform(c, 0, Vector2(1, 0.42))
			_over.draw_circle(Vector2.ZERO, w * (0.55 + 0.25 * h), Color(0.06, 0.06, 0.08, 0.6))   # umbra în apă
			_over.draw_circle(Vector2(0, -w * 0.25 * h), w * (0.45 + 0.2 * h), stone)
			_over.draw_circle(Vector2(-w * 0.15, -w * 0.38 * h), w * 0.18, stone.lightened(0.35 + 0.3 * lit))  # luciul ud
			_over.draw_set_transform(Vector2.ZERO)
		else:
			_over.draw_set_transform(c, 0, Vector2(1, 0.35))
			_over.draw_arc(Vector2.ZERO, w * 0.5, 0, TAU, 14, Color(0.75, 0.8, 0.95, 0.35), 1.0)
			_over.draw_set_transform(Vector2.ZERO)
		if _crossing and k == _stone_i:
			_over.draw_set_transform(c, 0, Vector2(1, 0.42))
			_over.draw_arc(Vector2.ZERO, w * 0.85, 0, TAU, 18, Color(1.0, 0.85, 0.5, 0.35 + 0.25 * sin(_t * 6.0)), 1.0)
			_over.draw_set_transform(Vector2.ZERO)
	for sp in _splashes:
		var p: Vector2 = sp[0]
		var age: float = sp[1]
		var big: float = sp[2]
		for i in 6:
			var ang := -PI * (0.15 + 0.7 * i / 5.0)
			var q := p + Vector2(cos(ang), sin(ang)) * (4.0 + age * 40.0) * big + Vector2(0, age * age * 60.0)
			_over.draw_rect(Rect2(q.round(), Vector2.ONE * (1 + int(big))), Color(0.8, 0.85, 1.0, 0.7 * (1.0 - age / 0.5)))


func _draw_over() -> void:
	_draw_stones()
	# vitrina birtului: lumină caldă care respiră ușor (televizorul dinăuntru)
	_over.draw_rect(PUB_WINDOW, Color(1.0, 0.85, 0.5, 0.06 + 0.05 * absf(sin(_t * 2.3))))
	# cercuri de ploaie în băltoace
	for r in _ripples:
		var age: float = r[1]
		var p: Vector2 = r[0]
		_over.draw_set_transform(p, 0, Vector2(1, 0.3))
		_over.draw_arc(Vector2.ZERO, 2.0 + age * 12.0, 0, TAU, 16, Color(0.75, 0.82, 1.0, 0.5 * (1.0 - age / 0.8)), 1.0)
	_over.draw_set_transform(Vector2.ZERO)
	# ploaia: fiecare strop e vizibil mai ales când e luminat din spate (felinar, vitrină)
	for dr in _rain:
		var L: Dictionary = RAIN_LAYERS[dr[1]]
		var p: Vector2 = dr[0]
		var lit := _light_at(p)
		var col := Color(0.66, 0.74, 0.92).lerp(Color(1.0, 0.78, 0.45), clampf(lit, 0.0, 1.0))
		col.a = clampf(L["alpha"] * (0.75 + 1.4 * lit), 0.0, 0.95)
		var tail: Vector2 = Vector2(-WIND, -1.0) * L["len"]
		_over.draw_line(p.round(), (p + tail).round(), col, 1.0)
	# stropi sparți pe drum: o mică coroană de 3 picături
	for sp in _splash:
		var q: Vector2 = sp[0]
		var k: float = sp[1] / 0.14
		var c := Color(0.75, 0.8, 0.95, 0.45 * (1.0 - k)).lerp(Color(1.0, 0.8, 0.5, 0.45 * (1.0 - k)), clampf(_light_at(q), 0.0, 1.0))
		var r := 1.0 + k * 2.0
		_over.draw_rect(Rect2(q + Vector2(-r, -1 - k * 2.0), Vector2.ONE), c)
		_over.draw_rect(Rect2(q + Vector2(r, -1 - k * 2.0), Vector2.ONE), c)
		_over.draw_rect(Rect2(q + Vector2(0, -2 - k * 3.0), Vector2.ONE), c)


## Felinarul (reparat de Romică acum trei ani) are contactul slab. Ritmul pâlpâitului e cel filmat de Veo
## (art/anim/felinar/curve.json, scos cu tools/art/light_from_video.py), iar imaginea stinsă e tot din video.
## După o serie, felinarul arde liniștit câteva secunde, apoi seria se reia.
func _update_lamp(d: float) -> void:
	if _curve.is_empty():
		_lamp_on = 1.0
		return
	if _hold > 0.0:
		_hold -= d
		_lamp_on = 1.0
		return
	_curve_t += d
	var k := int(_curve_t * _curve_fps)
	if k >= _curve.size():
		_curve_t = 0.0
		_hold = randf_range(4.0, 11.0)
		_lamp_on = 1.0
		return
	_lamp_on = float(_curve[k])


func _new_drop(layer_i: int, y: float) -> Array:
	# stropii din față cad mai jos pe ecran (sunt mai aproape), cei din spate se opresc lângă orizont
	var ground: float = [randf_range(205, 250), randf_range(240, 300), randf_range(280, 362)][layer_i]
	return [Vector2(randf_range(0, Game.W + 40), y), layer_i, ground]


## Cât de luminat e un punct din aer (0..1): felinarul (după cât e de aprins) și celelalte lumini.
func _light_at(p: Vector2) -> float:
	var k := clampf(1.0 - p.distance_to(LAMP + Vector2(0, 30)) / 150.0, 0.0, 1.0)
	var l := k * k * _lamp_on
	for g in GLOWS:
		var kg := clampf(1.0 - p.distance_to(g[0]) / g[1], 0.0, 1.0)
		l += kg * kg * g[2]
	return l


func _lamp() -> void:
	await say("Romică", "Pe ăsta l-am reparat eu acum trei ani. Ține de atunci! Mă rog... pâlpâie, dar ține.")


func _dog() -> void:
	Game.show_closeup("caine_tremura")
	await say("Romică", "Câinele lui Ilie. S-a băgat sub bancă, la uscat, și tremură ca varga.")
	await say("Romică", "Ne înțelegem noi doi: amândoi suntem dați afară din casă pe ploaie.")


func _gate() -> void:
	if Game.flags.get("ilie_done", false):
		await say("Nea Ilie", "Hai, du-te, Romică! Și pe pietre, nu prin apă!")
		return
	await say("Romică", "Nea Ilieee! Ești treaz?")
	if _ilie:
		_ilie.visible = true
	await say("Nea Ilie", "Cine-i acolo la ora asta? A, tu ești, Romică. Te-a dat afară Gina?")
	var a := await Game.choose(["„Nu m-a dat afară. Am ieșit eu, demn.”", "„M-a dat. Din cauza mașinii de spălat.”"])
	if a == 0:
		await say("Romică", "Nu m-a dat afară. Am ieșit eu, demn.")
		await say("Nea Ilie", "Demn, în cizme de cauciuc, la zece seara, pe ploaie. Ca toți bărbații demni din sat.")
	else:
		await say("Romică", "M-a dat. Din cauza mașinii de spălat.")
		await say("Nea Ilie", "Aia pe care ai legat-o cu sârmă? Am auzit-o de aici. Credeam că aterizează un elicopter.")
	await say("Nea Ilie", "Bine că veniși. Mi s-a stricat zăvorul la poartă și câinele iese la drum. Că tot ești meșter...")
	var b := await Game.choose(["Îi legi zăvorul cu sârmă.", "„Mâine, nea Ilie, că acum mă grăbesc.”"])
	if b == 0:
		await say("Romică", "Ia să vedem... O tură de sârmă, două de bandă... Gata. Ține până la primăvară.")
		await say("Nea Ilie", "Până la primăvară sau până trântesc poarta?")
		await say("Romică", "Până la primăvară, dacă n-o trântești.")
		Game.flags["zavor_ilie"] = true
	else:
		await say("Romică", "Mâine, nea Ilie, că acum mă grăbesc.")
		await say("Nea Ilie", "Te grăbești la birt. Bine, bine. Atunci leagă câinele de bancă, să nu te urmeze.")
	await say("Nea Ilie", "Și ai grijă, că la birt e apă mare. Treci pe pietrele de la fântână, le-am pus eu. Dar calcă doar când ies din apă!")
	Game.flags["ilie_done"] = true
	if _ilie:
		_ilie.visible = false


## Minijocul: treci băltoaca din piatră în piatră; calci doar pe piatra următoare, când e deasupra apei.
func _stone(k: int) -> void:
	if not _crossing:
		await _pub()
		return
	if k != _stone_i:
		return
	var c: Vector2 = _stones[k][0]
	if _stone_up(k) < 0.0:
		_splashes.append([c, 0.0, 1.0])
		Game.shake(3.0, 0.25)
		await say("Romică", ["Mi-am umplut cizma!", "Aoleu, până la genunchi!", "Asta nu era piatră, era băltoaca."].pick_random())
		_stone_i = 0
		await say("Romică", "Hai înapoi, de la început. Și calc doar când iese piatra din apă.")
		return
	_splashes.append([c, 0.0, 0.4])
	_stone_i += 1
	if _stone_i >= _stones.size():
		_crossing = false
		await say("Romică", "Am trecut! Uscat... aproape.")
		Game.goto("pub")


func _pub() -> void:
	if not Game.flags.get("ilie_done", false):
		await say("Romică", "Între mine și birt e o băltoacă cât Dunărea. Poate știe nea Ilie pe unde se trece.")
		return
	if not _crossing:
		_crossing = true
		_stone_i = 0
		await say("Romică", "Pietrele lui nea Ilie. Una câte una, și doar când ies din apă.")
		return

