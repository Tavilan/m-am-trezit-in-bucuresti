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
var _latch: Node            # minijocul cu zăvorul (prim-plan), cât timp e deschis


func _ready() -> void:
	title = "Drumul prin sat, noaptea"
	horizon = 200   # punctul de fugă al drumului
	# lumina: noapte albastră, felinarul (portocaliu) și vitrina birtului (caldă)
	lighting = {"ambient": Vector3(0.7, 0.72, 0.9), "saturation": 0.9,
		"light1_pos": LAMP, "light1_color": Vector3(1.0, 0.7, 0.35), "light1_radius": 400.0, "light1_strength": 0.9,
		"light2_pos": Vector2(485, 190), "light2_color": Vector3(1.0, 0.8, 0.45), "light2_radius": 120.0, "light2_strength": 0.3}
	grade = {"tint": Vector3(0.66, 0.66, 0.8), "saturation": 0.68}
	ambience = "res://audio/drum_sat.ogg"   # ploaie + câini care latră departe, prin curți
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
	hotspot("Banca", Rect2(36, 182, 70, 30), _bench)
	hotspot("Băltoaca", Rect2(240, 300, 220, 58), _puddle)
	hotspot("Luna", Rect2(420, 26, 30, 30), _moon)
	# Nea Ilie apare la poartă după ce îl strigi (dacă arta lui e gata)
	if ResourceLoader.exists("res://art/final/ilie_drum.png"):
		_ilie = layer("res://art/final/ilie_drum.png", Vector2(168, 252))
		figure(_ilie, "Nea Ilie")
		_ilie.visible = false



func enter() -> void:
	await say("Romică", "Toarnă cu găleata. Și Gina tot mai rea ca ploaia.")


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
	_over.queue_redraw()


func _draw_over() -> void:
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
	await cycle("lamp", [
		"Stâlpu' ăsta l-am reparat io acum trei ani. Ține de-atunci! Mă rog... clipește, da' ține.",
		"Primăria zice că-l schimbă. Zice de două mandate.",
		"Dacă-i dai un picior în stâlp, se aprinde mai tare. Nu-i dau, că plouă.",
	])


func _dog() -> void:
	Game.show_closeup("caine_tremura")
	await cycle("dog", [
		"Cățelu' lu' Ilie. S-a băgat sub bancă la uscat și tremură ca varga.",
		"Ne-nțelegem noi doi: amândoi dați afară din casă pe ploaie.",
		"Cuțu, cuțu... Nu, n-am nimic de mâncare. Am șapte lei, și ăia-s numărați.",
	])


func _gate() -> void:
	if Game.flags.get("ilie_done", false):
		await cycle("gate_done", [
			"Zăvoru' lu' nea Ilie. Ține. Până la primăvară, cel puțin.",
			"Dacă iese câinele acu', iese pe gard. Pe-acolo nu mai răspund io.",
		])
		return
	await cycle("gate", [
		"Poarta lu' nea Ilie. A pus streașină, să nu-i plouă câinele.",
		"Poarta asta am mai adus-o o dată acasă la mine. Pe spate. Nu mai țiu de ce.",
	])


func _bench() -> void:
	await cycle("bench", [
		"Banca de la poartă. Aici stă Ilie vara și numără mașinile. Două pe zi, cu tot cu-a poștei.",
		"E udă leoarcă. Nu mă așez, că mă duc la birt cu curu' ud și râde Costel.",
	])


func _puddle() -> void:
	await cycle("puddle", [
		"Băltoaca asta e aici din '89. A văzut mai multe guverne decât mine.",
		"Când a venit asfaltu' în comună, s-a oprit fix la poarta lu' Ilie. De-aici încolo e glod.",
	])


func _moon() -> void:
	await cycle("moon", [
		"Plouă și se vede luna. Ăsta-i semn. Nu știu de ce, da' semn e.",
		"Pe lună au ajuns americanii. La noi n-a ajuns canalizarea.",
	])


## Nea Ilie te strigă de la poartă când pornești spre birt (nu-l chemi tu).
func _ilie_calls() -> void:
	if _ilie:
		_ilie.visible = true
	await say("Nea Ilie", "Romică! Băi Romică! Stai, mă, un pic!")
	await say("Nea Ilie", "Unde-mi umbli pe potopu' ăsta? Te-a dat Gina afară?")
	var a := await Game.choose(["„Nu m-a dat nimeni. Plecai io.”", "„M-a dat. Pentru mașina de spălat.”"])
	if a == 0:
		await say("Romică", "Nu m-a dat nimeni. Plecai io.")
		await say("Nea Ilie", "Plecași tu. În cizme, la zece noaptea, pe ploaie. Ca tot omu' care pleacă de bunăvoie.")
	else:
		await say("Romică", "M-a dat. Pentru mașina de spălat.")
		await say("Nea Ilie", "Aia legată cu sârmă? O aud de la mine. Ziceam că aterizează elicopteru' de la SMURD.")
	await say("Nea Ilie", "Bine că treci. Mi s-a rupt zăvoru' de la poartă, și javra iese la drum.")
	await say("Nea Ilie", "Dacă iese, mâine-i la birt înaintea ta. Și nu plătește.")
	var b := await Game.choose(["„Dă-l încoa', că-l leg acu'.”", "„Mâine, nea Ilie. Acu' mă grăbesc.”"])
	if b == 1:
		await say("Romică", "Mâine, nea Ilie. Acu' mă grăbesc.")
		await say("Nea Ilie", "Mâine? La noapte pleacă după cățelele din Dăneasa și nu-l mai văd o săptămână. Două minute, Romică!")
	await say("Romică", "Bine, mă, bine. Sârmă am la mine. Am mereu.")
	await _latch_game()
	Game.flags["ilie_done"] = true
	await say("Nea Ilie", "Ține? Ține! Să-ți dea Dumnezeu sănătate, Romică.")
	await say("Nea Ilie", "Du-te la birt, că-i acolo nepotu-tău, neamțu'. Zice la toată lumea că tu-l învățași meserie și că-i pare rău.")
	await say("Romică", "Îi pare rău? De ce?")
	await say("Nea Ilie", "Nu știu, mă. Așa zice. Și râd toți.")
	if _ilie:
		_ilie.set_meta("gone", true)   # a intrat în curte; nu-l mai readuce portretul
		_ilie.visible = false


## Minijocul cu zăvorul: tragi cu degetul în cerc în jurul zăvorului, ca să răsucești sârma.
## Prea repede: sârma se întinde prea tare și se rupe. Dacă te oprești: se desface. 4 ture și gata.
func _latch_game() -> void:
	_latch = preload("res://scripts/scenes/latch_game.gd").new()
	Game.world.get_parent().add_child(_latch)
	await say("Romică", "Răsucesc sârma pe zăvor. Rotund și cu răbdare: dacă trag tare, se rupe; dacă mă opresc, se desface.")
	var res: String = await _latch.finished
	_latch.queue_free()
	_latch = null


func _pub() -> void:
	if not Game.flags.get("ilie_done", false):
		await _ilie_calls()
		return
	await say("Romică", "Birtul Unirea. Hai să vedem ce zice neamțu'.")
	Game.goto("pub")
