extends GameScene
## 2. Drumul prin sat, noaptea, pe ploaie. Birtul Unirea luminat la capătul drumului.
## Artă: fundal + câinele lui Ilie (strat separat); ploaia, băltoacele, felinarul și vitrina sunt animate din cod.

const LAMP := Vector2(170, 22)            # becul felinarului de pe stâlp
const PUB_WINDOW := Rect2(452, 170, 66, 36)
const PUDDLES := [Vector2(150, 330), Vector2(250, 290), Vector2(440, 305), Vector2(520, 300), Vector2(590, 340), Vector2(300, 345)]

var _t := 0.0
var _rain: Array = []
var _ripples: Array = []   # [poziție, vârstă]
var _lamp_on := 1.0
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
	var dog := layer("res://art/final/caine_ilie_drum.png", Vector2(236, 335))
	_dog_sprite = dog
	_over = Node2D.new()
	_over.draw.connect(_draw_over)
	add_child(_over)
	for i in 160:
		_rain.append(Vector2(randf_range(0, Game.W), randf_range(0, Game.H)))
	hotspot("Felinarul", Rect2(104, 0, 40, 265), _lamp)
	hotspot("Câinele lui Ilie", Rect2(dog.position, dog.texture.get_size()), _dog)
	hotspot("Birtul Unirea", Rect2(412, 120, 140, 92), _pub)


func enter() -> void:
	await say("Romică", "Ce noapte frumoasă... Și ce ceartă urâtă.")


func _process(d: float) -> void:
	_t += d
	for i in _rain.size():
		var p: Vector2 = _rain[i]
		p += Vector2(-30, 260) * d
		if p.y > Game.H:
			p = Vector2(randf_range(0, Game.W + 60), randf_range(-20, 0))
		_rain[i] = p
	if randf() < d * 6.0:
		_ripples.append([PUDDLES[randi() % PUDDLES.size()] + Vector2(randf_range(-20, 20), randf_range(-4, 4)), 0.0])
	for r in _ripples:
		r[1] += d
	_ripples = _ripples.filter(func(r): return r[1] < 0.8)
	# felinarul pâlpâie (reparat de Romică acum trei ani): uneori se stinge o clipă
	if _lamp_on > 0.5 and randf() < d * 0.6:
		_lamp_on = 0.0
	elif _lamp_on < 0.5 and randf() < d * 8.0:
		_lamp_on = 1.0
	(_dog_sprite.material as ShaderMaterial).set_shader_parameter("light1_strength", 0.75 * _lamp_on)
	_over.queue_redraw()


func _draw_over() -> void:
	# lumina felinarului; când pâlpâie, întunecă puțin colțul din stânga
	if _lamp_on > 0.5:
		_over.draw_circle(LAMP, 30, Color(1.0, 0.8, 0.4, 0.14 + randf_range(-0.02, 0.02)))
		_over.draw_circle(LAMP, 12, Color(1.0, 0.85, 0.5, 0.22))
	else:
		_over.draw_rect(Rect2(0, 0, 300, Game.H), Color(0.02, 0.03, 0.08, 0.28))
	# vitrina birtului: lumină caldă care respiră ușor (televizorul dinăuntru)
	_over.draw_rect(PUB_WINDOW, Color(1.0, 0.85, 0.5, 0.06 + 0.05 * absf(sin(_t * 2.3))))
	# cercuri de ploaie în băltoace
	for r in _ripples:
		var age: float = r[1]
		var p: Vector2 = r[0]
		_over.draw_set_transform(p, 0, Vector2(1, 0.3))
		_over.draw_arc(Vector2.ZERO, 2.0 + age * 12.0, 0, TAU, 16, Color(0.75, 0.82, 1.0, 0.5 * (1.0 - age / 0.8)), 1.0)
	_over.draw_set_transform(Vector2.ZERO)
	# ploaia
	for p in _rain:
		_over.draw_line(p.round(), (p + Vector2(-1, 6)).round(), Color(0.7, 0.78, 0.95, 0.28), 1.0)


func _lamp() -> void:
	await say("Romică", "Pe ăsta l-am reparat eu acum trei ani. Ține de atunci! Mă rog... pâlpâie, dar ține.")


func _dog() -> void:
	await say("Romică", "Câinele lui Ilie. Latră la toată lumea, numai la mine nu. Ne înțelegem: suntem amândoi certați cu nevasta.")


func _pub() -> void:
	Game.goto("pub")
