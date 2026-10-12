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
var _lamp_plan: Array = []  # [durată, stare] pași de pâlpâit rămași
var _lamp_wait := 4.0
var _lamp_mat: ShaderMaterial
var _hum := 0.0
var _over: Node2D
var _dog_sprite: Sprite2D


func _ready() -> void:
	title = "Drumul prin sat, noaptea"
	horizon = 200   # punctul de fugă al drumului
	# lumina: noapte albastră, felinarul (portocaliu) și vitrina birtului (caldă)
	lighting = {"ambient": Vector3(0.56, 0.6, 0.8), "saturation": 0.85,
		"light1_pos": LAMP, "light1_color": Vector3(1.0, 0.7, 0.35), "light1_radius": 300.0, "light1_strength": 0.75,
		"light2_pos": Vector2(485, 190), "light2_color": Vector3(1.0, 0.8, 0.45), "light2_radius": 120.0, "light2_strength": 0.3}
	background("res://art/final/drum_fundal.png")
	# fundalul = varianta stinsă + lumina felinarului înmulțită cu intensitatea (shaders/light_mix.gdshader)
	_lamp_mat = ShaderMaterial.new()
	_lamp_mat.shader = preload("res://shaders/light_mix.gdshader")
	_lamp_mat.set_shader_parameter("off_tex", load("res://art/final/drum_fundal_felinar_stins.png"))
	_bg.material = _lamp_mat
	var dog := layer("res://art/final/caine_ilie_drum.png", Vector2(236, 335))
	_dog_sprite = dog
	_over = Node2D.new()
	_over.draw.connect(_draw_over)
	add_child(_over)
	for li in RAIN_LAYERS.size():
		for i in RAIN_LAYERS[li]["n"]:
			_rain.append(_new_drop(li, randf_range(-20, Game.H)))
	hotspot("Felinarul", Rect2(104, 0, 40, 265), _lamp)
	hotspot("Câinele lui Ilie", Rect2(dog.position, dog.texture.get_size()), _dog)
	hotspot("Birtul Unirea", Rect2(412, 120, 140, 92), _pub)


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
	(_dog_sprite.material as ShaderMaterial).set_shader_parameter("light1_strength", 0.75 * _lamp_on)
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


## Felinarul (reparat de Romică acum trei ani) are contactul slab. Ca la becurile reale de stradă:
## lumina nu se stinge brusc la negru, ci „cade” la 30–60% și revine, în serii neregulate; rar se
## stinge aproape de tot o fracțiune de secundă și se reaprinde roșiatic, apoi se încălzește la galben.
## Între serii are un tremur fin, abia vizibil (rețeaua de la țară).
func _update_lamp(d: float) -> void:
	if _lamp_plan.is_empty():
		_lamp_wait -= d
		if _lamp_wait <= 0.0:
			_lamp_wait = randf_range(3.0, 8.0)
			for i in randi_range(2, 6):
				_lamp_plan.append([randf_range(0.03, 0.09), randf_range(0.3, 0.6)])
				_lamp_plan.append([randf_range(0.04, 0.16), randf_range(0.85, 1.0)])
			if randf() < 0.3:
				_lamp_plan.append([randf_range(0.12, 0.35), 0.08])
				_lamp_plan.append([0.35, 0.3])
				_lamp_plan.append([0.5, 0.65])
				_lamp_plan.append([0.6, 0.9])
		_hum += d * 7.0
		_lamp_target = 0.97 + 0.03 * sin(_hum) * sin(_hum * 0.37)
	else:
		_lamp_plan[0][0] -= d
		_lamp_target = _lamp_plan[0][1]
		if _lamp_plan[0][0] <= 0.0:
			_lamp_plan.pop_front()
	# lumina scade repede și crește puțin mai lent (filamentul are inerție termică)
	var rate := 1.0 / 0.04 if _lamp_target < _lamp_on else 1.0 / 0.12
	_lamp_on = move_toward(_lamp_on, _lamp_target, d * rate)


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
	await say("Romică", "Câinele lui Ilie. Latră la toată lumea, numai la mine nu. Ne înțelegem: suntem amândoi certați cu nevasta.")


func _pub() -> void:
	Game.goto("pub")
