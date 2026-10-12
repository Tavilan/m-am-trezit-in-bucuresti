extends GameScene
## 1. Bucătăria lui Romică, seara. Cearta cu Gina; mașina de spălat „reparată” se plimbă prin bucătărie.
## Artă: fundal + Gina + mașina de spălat (straturi separate); ploaia, becul și candela sunt animate din cod.

const WARM := Color(1.0, 0.93, 0.82)      # lumina becului peste personaje și obiecte
const WINDOW := Rect2(366, 86, 128, 66)   # geamul (ploaia se vede doar aici)

var _washer: Sprite2D
var _washer_home := Vector2.ZERO
var _gina: Sprite2D
var _t := 0.0
var _rain: Array = []
var _shake := 1.0
var _under: Node2D   # umbrele, sub personaje
var _over: Node2D    # ploaia, lumina, peste fundal


func _ready() -> void:
	title = "Acasă la Romică, seara"
	background("res://art/final/bucatarie_fundal.png")
	_under = Node2D.new()
	_under.draw.connect(_draw_under)
	add_child(_under)
	_washer = layer("res://art/final/masina_spalat_bucatarie.png", Vector2(220, 322))
	_washer.modulate = WARM
	_washer_home = _washer.position
	_gina = layer("res://art/final/gina_bucatarie.png", Vector2(352, 330))
	_gina.modulate = WARM
	var h := hotspot("Mașina de spălat", Rect2(Vector2.ZERO, _washer.texture.get_size()), _washer_talk)
	remove_child(h)
	_washer.add_child(h)
	hotspot("Gina", Rect2(316, 134, 74, 196), _gina_talk)
	hotspot("Icoana", Rect2(540, 10, 46, 56), _icon)
	hotspot("Ușa", Rect2(14, 4, 86, 320), _door)
	_over = Node2D.new()
	_over.draw.connect(_draw_over)
	add_child(_over)
	for i in 70:
		_rain.append(Vector2(randf_range(0, WINDOW.size.x), randf_range(0, WINDOW.size.y)))


func enter() -> void:
	await say("Gina", "Romicăăă! Ce-ai făcut, mă, la mașina de spălat?!")
	await say("Romică", "O reparai. Merge, nu?")
	await say("Gina", "Merge! Merge prin toată bucătăria! Uite-o că vine spre mine!")


func _process(d: float) -> void:
	_t += d
	# mașina centrifughează: tremură și se plimbă încet stânga-dreapta pe linoleum
	var walk := sin(_t * 0.45) * 26.0
	_washer.position = (_washer_home + Vector2(walk + randf_range(-_shake, _shake), randf_range(-_shake, _shake))).round()
	for i in _rain.size():
		var p: Vector2 = _rain[i]
		p.y += d * 70.0
		p.x -= d * 8.0
		if p.y > WINDOW.size.y:
			p = Vector2(randf_range(0, WINDOW.size.x + 10), -randf_range(0, 10))
		_rain[i] = p
	_under.queue_redraw()
	_over.queue_redraw()


func _draw_under() -> void:
	# umbre de contact sub Gina și sub mașină
	_under.draw_set_transform(Vector2(352, 330), 0, Vector2(1, 0.25))
	_under.draw_circle(Vector2.ZERO, 30, Color(0, 0, 0, 0.28))
	_under.draw_set_transform(_washer.position + Vector2(_washer.texture.get_width() / 2.0, _washer.texture.get_height() - 1), 0, Vector2(1, 0.22))
	_under.draw_circle(Vector2.ZERO, 50, Color(0, 0, 0, 0.3))
	_under.draw_set_transform(Vector2.ZERO)


func _draw_over() -> void:
	# picături pe geam, peste noaptea de afară
	for p in _rain:
		var q: Vector2 = WINDOW.position + p
		if WINDOW.has_point(q):
			_over.draw_line(q.round(), (q + Vector2(-1, 4)).round(), Color(0.7, 0.8, 1.0, 0.35), 1.0)
	# becul și candela pâlpâie ușor
	var bulb := 0.16 + 0.02 * sin(_t * 9.0) + randf_range(-0.01, 0.01)
	_over.draw_circle(Vector2(320, 20), 34, Color(1.0, 0.85, 0.5, bulb * 0.5))
	_over.draw_circle(Vector2(320, 20), 16, Color(1.0, 0.9, 0.6, bulb))
	var flame := 0.22 + 0.08 * sin(_t * 13.0) * sin(_t * 3.1) + randf_range(-0.03, 0.03)
	_over.draw_circle(Vector2(524, 46), 9, Color(1.0, 0.7, 0.3, flame))


func _gina_talk() -> void:
	if Game.flags.get("gina_done", false):
		await say("Gina", "Ce mai stai? Du-te!")
		return
	await say("Romică", "Gino, fă, ascultă-mă...")
	var i := await Game.choose(["„Las' că o mai leg o dată, mai strâns.”", "„Mă duc până la birt, să mă gândesc la o soluție.”"])
	if i == 0:
		await say("Romică", "Las' că o mai leg o dată. Mai strâns. Cu sârmă de-aia groasă.")
		await say("Gina", "Să nu te mai prind cu sârma ta în casa mea!")
	else:
		await say("Romică", "Mă duc până la birt. Acolo îmi vin ideile.")
		await say("Gina", "Ideile tale ne-au lăsat fără mașină de spălat!")
	await say("Gina", "Du-te, du-te! Și să nu te mai întorci până nu te trezești!")
	Game.flags["gina_done"] = true


func _washer_talk() -> void:
	_shake = 3.0
	await say("Romică", "Sârmă de doi milimetri, legată ca la carte. Problema e la centrifugă, nu la mine.")
	_shake = 1.0


func _icon() -> void:
	await say("Romică", "Doamne, ajută-mă să nu mai repar nimic azi.")


func _door() -> void:
	if not Game.flags.get("gina_done", false):
		await say("Romică", "Întâi să-i zic ceva Ginei. Să nu zică că plecai ca un hoț.")
		return
	await say("Romică", "Plecai.")
	Game.goto("road")
