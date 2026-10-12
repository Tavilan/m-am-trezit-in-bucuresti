extends GameScene
## 1. Bucătăria lui Romică, seara. Cearta cu Gina; mașina de spălat „reparată” se plimbă prin bucătărie.
## Artă: fundal + Gina + mașina de spălat (straturi separate); ploaia, becul și candela sunt animate din cod.

const GINA_FEET := Vector2(330, 318)
const WINDOW := Rect2(368, 84, 126, 69)   # geamul (ploaia se vede doar aici)

var _washer: Sprite2D
var _washer_home := Vector2.ZERO
var _gina: Sprite2D
var _t := 0.0
var _rain: Array = []       # ploaia de afară, văzută prin geam: [poziție]
var _drops: Array = []      # picături lipite de geam: [poziție, viteză de alunecare (0 = stă)]
var _trails: Array = []     # urme lăsate de picăturile care alunecă: [poziție, vârstă]
var _glass: Image           # masca geamului (alb = sticlă), ca ploaia să nu treacă peste ghiveci sau ramă
var _shake := 1.0
var _walk_amp := 26.0
var _stopped := false        # mașina oprită (minijocul cu ștecherul)
var _plug_game := false      # minijocul e pornit
const SOCKET := Rect2(171, 243, 8, 10)   # priza de pe perete, în spatele mașinii
var _under: Node2D   # umbrele, sub personaje
var _over: Node2D    # ploaia, lumina, peste fundal


func _ready() -> void:
	title = "Acasă la Romică, seara"
	horizon = 108   # linia ochilor (1,55 m) pe peretele din fund: Gina 1,68 m, mașina 85 cm
	# lumina: seară caldă și slabă, becul din tavan (cald) și geamul (rece, albastru)
	lighting = {"ambient": Vector3(0.74, 0.66, 0.58), "saturation": 0.92,
		"light1_pos": Vector2(320, 20), "light1_color": Vector3(1.0, 0.82, 0.55), "light1_radius": 330.0, "light1_strength": 0.6,
		"light2_pos": Vector2(430, 120), "light2_color": Vector3(0.45, 0.55, 0.9), "light2_radius": 150.0, "light2_strength": 0.28}
	grade = {"tint": Vector3(0.9, 0.82, 0.74), "saturation": 0.72}
	background("res://art/final/bucatarie_fundal.png")
	_under = Node2D.new()
	_under.draw.connect(_draw_under)
	add_child(_under)
	_washer = layer("res://art/final/masina_spalat_bucatarie.png", Vector2(196, 324))
	_washer_home = _washer.position
	_gina = layer("res://art/final/gina_bucatarie.png", GINA_FEET)
	figure(_gina, "Gina")
	# halatul de satin e foarte saturat: îl aducem la lumina slabă a becului, ca mașina de spălat
	var gm := _gina.material as ShaderMaterial
	gm.set_shader_parameter("saturation", 0.55)
	gm.set_shader_parameter("ambient", Vector3(0.64, 0.57, 0.52))
	gm.set_shader_parameter("light1_strength", 0.42)
	var h := hotspot("Mașina de spălat", Rect2(Vector2.ZERO, _washer.texture.get_size()), _washer_talk)
	remove_child(h)
	_washer.add_child(h)
	hotspot("Gina", Rect2(_gina.position, _gina.texture.get_size()), _gina_talk)
	hotspot("Icoana", Rect2(540, 10, 46, 56), _icon)
	hotspot("Geaca de pe cuier", Rect2(102, 42, 50, 165), _coat)
	hotspot("Cizmele", Rect2(120, 222, 52, 50), _boots)
	hotspot("Mușamaua de pe masă", Rect2(402, 178, 160, 60), _oilcloth)
	hotspot("Radioul", Rect2(224, 46, 56, 30), _radio)
	hotspot("Calendarul", Rect2(152, 64, 48, 72), _calendar)
	hotspot("Ușa", Rect2(14, 4, 86, 320), _door)
	hotspot("Priza", SOCKET.grow(6), _socket)
	_over = Node2D.new()
	_over.draw.connect(_draw_over)
	add_child(_over)
	_glass = (load("res://art/final/bucatarie_geam_masca.png") as Texture2D).get_image()
	for i in 60:
		_rain.append(WINDOW.position + Vector2(randf_range(0, WINDOW.size.x), randf_range(0, WINDOW.size.y)))
	for i in 55:
		_drops.append([WINDOW.position + Vector2(randi_range(0, int(WINDOW.size.x)), randi_range(0, int(WINDOW.size.y))), 0.0])


func enter() -> void:
	await say("Gina", "Romicăăă! Ce-ai făcut, mă, la mașina de spălat?!")
	await say("Romică", "O reparai. Merge, nu?")
	await say("Gina", "Merge! Merge prin toată bucătăria! Uite-o că vine spre mine! Oprește-o, până nu-mi rupe linoleumul!")


func _process(d: float) -> void:
	_t += d
	# mașina centrifughează: tremură și se plimbă încet stânga-dreapta pe linoleum
	if not _stopped:
		var walk := sin(_t * 0.45) * _walk_amp
		_washer.position = (_washer_home + Vector2(walk + randf_range(-_shake, _shake), randf_range(-_shake, _shake))).round()
	# ploaia de afară cade repede, ușor înclinată
	for i in _rain.size():
		var p: Vector2 = _rain[i]
		p += Vector2(-12, 150) * d
		if p.y > WINDOW.end.y:
			p = Vector2(randf_range(WINDOW.position.x, WINDOW.end.x + 8), WINDOW.position.y - randf_range(0, 8))
		_rain[i] = p
	# picăturile de pe geam: din când în când una se adună și alunecă în jos, șerpuit, lăsând urmă
	if randf() < d * 2.5:
		var dr: Array = _drops[randi() % _drops.size()]
		if dr[1] == 0.0:
			dr[1] = randf_range(18.0, 45.0)
	for dr in _drops:
		if dr[1] > 0.0:
			var old_p: Vector2 = dr[0]
			dr[0] += Vector2(sin(_t * 9.0 + old_p.x) * 4.0 * d, dr[1] * d)
			if Vector2i(dr[0]) != Vector2i(old_p):
				_trails.append([old_p.round(), 0.0])
			if dr[0].y > WINDOW.end.y or not _on_glass(dr[0]):
				dr[0] = WINDOW.position + Vector2(randi_range(0, int(WINDOW.size.x)), randi_range(0, 20))
				dr[1] = 0.0
	for tr in _trails:
		tr[1] += d
	_trails = _trails.filter(func(tr): return tr[1] < 1.6)
	_under.queue_redraw()
	_over.queue_redraw()


func _on_glass(p: Vector2) -> bool:
	var x := int(p.x)
	var y := int(p.y)
	if x < 0 or y < 0 or x >= _glass.get_width() or y >= _glass.get_height():
		return false
	return _glass.get_pixel(x, y).r > 0.5


func _draw_under() -> void:
	# priza de pe perete și cablul mașinii (se văd doar când mașina pleacă de lângă perete)
	_under.draw_rect(SOCKET, Color(0.72, 0.68, 0.6))
	_under.draw_rect(SOCKET, Color(0.35, 0.3, 0.25), false, 1.0)
	_under.draw_rect(Rect2(SOCKET.position + Vector2(2, 4), Vector2(1, 2)), Color(0.15, 0.12, 0.1))
	_under.draw_rect(Rect2(SOCKET.position + Vector2(5, 4), Vector2(1, 2)), Color(0.15, 0.12, 0.1))
	if not _stopped:
		var back := _washer.position + Vector2(_washer.texture.get_width() * 0.3, _washer.texture.get_height() * 0.55)
		var plug := SOCKET.get_center()
		var mid := (plug + back) / 2.0 + Vector2(0, 14)
		_under.draw_polyline(PackedVector2Array([plug, mid, back]), Color(0.12, 0.1, 0.1), 2.0)
	else:
		_under.draw_line(Vector2(SOCKET.position.x, SOCKET.end.y + 6), Vector2(SOCKET.position.x + 10, SOCKET.end.y + 12), Color(0.12, 0.1, 0.1), 2.0)
	# umbre de contact sub Gina și sub mașină
	if _gina.visible:
		_under.draw_set_transform(GINA_FEET, 0, Vector2(1, 0.25))
		_under.draw_circle(Vector2.ZERO, 34, Color(0, 0, 0, 0.3))
	_under.draw_set_transform(_washer.position + Vector2(_washer.texture.get_width() / 2.0, _washer.texture.get_height() - 1), 0, Vector2(1, 0.22))
	_under.draw_circle(Vector2.ZERO, 50, Color(0, 0, 0, 0.3))
	_under.draw_set_transform(Vector2.ZERO)


func _draw_over() -> void:
	# ploaia de afară, doar pe sticlă
	for p in _rain:
		for k in 4:
			var q: Vector2 = (p + Vector2(0.3 * k, -k)).round()
			if _on_glass(q):
				_over.draw_rect(Rect2(q, Vector2.ONE), Color(0.62, 0.72, 0.95, 0.28 - k * 0.05))
	# urmele umede lăsate pe geam
	for tr in _trails:
		if _on_glass(tr[0]):
			_over.draw_rect(Rect2(tr[0], Vector2.ONE), Color(0.55, 0.68, 0.95, 0.22 * (1.0 - tr[1] / 1.6)))
	# picăturile: un punct luminos (reflexia becului) cu o umbră mică dedesubt
	for dr in _drops:
		var q: Vector2 = Vector2(dr[0]).round()
		if _on_glass(q):
			_over.draw_rect(Rect2(q, Vector2.ONE), Color(0.85, 0.9, 1.0, 0.75 if dr[1] > 0.0 else 0.5))
			if _on_glass(q + Vector2(0, 1)):
				_over.draw_rect(Rect2(q + Vector2(0, 1), Vector2.ONE), Color(0.05, 0.08, 0.18, 0.35))
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
	if not _stopped:
		await say("Gina", "Nu vorbesc cu tine până nu oprești drăcia aia!")
		return
	await say("Gina", "Treizeci de ani, Romică. Treizeci de ani de sârmă și bandă izolatoare.")
	var a := await Game.choose(["„Bandă izolatoare de calitate, fă! Nemțească!”", "„Gino, mâine chem un meșter adevărat.”", "„Ce vrei, să dau bani pe una nouă?”"])
	match a:
		0:
			await say("Romică", "Bandă izolatoare de calitate, fă! Nemțească!")
			await say("Gina", "Nemțească... Și Marius e de-acum nemțesc. Măcar el, când strică ceva, cheamă pe altul.")
		1:
			await say("Romică", "Gino, mâine chem un meșter adevărat.")
			await say("Gina", "Meșter adevărat? Tu EȘTI meșterul satului, Romică! De-aia nu merge nimic în sat.")
		2:
			await say("Romică", "Ce vrei, să dau bani pe una nouă?")
			await say("Gina", "Da! Ca oamenii! Marius are în Germania una care vorbește!")
			await say("Romică", "Și ce zice?")
			await say("Gina", "Zice că-s gata rufele! Nu ca tine, care știi să zici doar „merge”.")
	await say("Gina", "Și unde te duci la ora asta, pe ploaia asta?")
	var b := await Game.choose(["„La birt. Să mă sfătuiesc cu oamenii.”", "„Nicăieri. Stau aici, cu tine.”"])
	if b == 0:
		await say("Romică", "La birt. Să mă sfătuiesc cu oamenii.")
		await say("Gina", "Cu Costel? Ăla și-a reparat frigiderul cu tine și acum ține berea în fântână.")
	else:
		await say("Romică", "Nicăieri. Stau aici, cu tine.")
		await say("Gina", "Cu mine? Să-mi repari și mie ceva? Nu, mersi. Du-te la birt!")
	await say("Gina", "Și să nu cumva să dai banii pe țuică!")
	var c := await Game.choose(["„Care bani? Eu n-am bani.”", "„Promit. Doar o bere.”", "„Ți-i dau ție, să mi-i păstrezi.”"])
	match c:
		0:
			await say("Romică", "Care bani? Eu n-am bani.")
			await say("Gina", "Lasă, că știu eu unde-i ascunzi. În geacă, sub mușama, în cizmă... Treizeci de ani, Romică!")
		1:
			await say("Romică", "Promit. Doar o bere.")
			await say("Gina", "O bere. Ca data trecută, când ai venit acasă cu poarta lu' Ilie în spate.")
		2:
			await say("Romică", "Ți-i dau ție, să mi-i păstrezi.")
			await say("Gina", "Păstrează-i tu. Că dacă ți-i țin eu, mâine mi-i ceri înapoi cu dobândă.")
			Game.flags["gina_soft"] = true
	await say("Gina", "Du-te, du-te! Și să nu te mai întorci până nu te trezești!")
	Game.flags["gina_done"] = true


func _washer_talk() -> void:
	if _stopped:
		await say("Romică", "Stă cuminte. Mâine o leg și de calorifer, să nu mai plece.")
		return
	_shake = 3.0
	await say("Romică", "Sârmă de doi milimetri, legată ca la carte. Problema e la centrifugă, nu la mine.")
	_shake = 1.0
	if not _plug_game:
		await say("Romică", "Ștecherul e în priza din spatele ei. Trebuie să-l prind când pleacă de lângă perete.")
		_plug_game = true
		_walk_amp = 46.0


## Minijocul: scoți ștecherul doar când mașina s-a îndepărtat de priză; altfel te lovește.
func _socket() -> void:
	if _stopped:
		await say("Romică", "Priza. Am pus-o eu în '94. Încă ține.")
		return
	var covered := _washer.position.x < SOCKET.end.x + 4 and _washer.position.x + _washer.texture.get_width() > SOCKET.position.x - 4
	if covered:
		Game.shake(4.0, 0.35)
		await say("Romică", ["Au! M-a lovit cu centrifuga!", "Stai, fă, că nu te fur!", "Îi ia pe toți la rând... Încă o dată."].pick_random())
		_plug_game = true
		_walk_amp = 46.0
		return
	_stopped = true
	_shake = 0.0
	Game.shake(2.0, 0.2)
	await say("Romică", "Gata! Am oprit-o.")
	await say("Gina", "Ai oprit-o scoțând-o din priză. Asta face și Mioara, și ea n-a făcut școală de electrician.")
	await say("Romică", "Ai văzut? Merge și oprită.")


func _coat() -> void:
	if Game.flags.get("lei_geaca", false):
		await say("Romică", "Geaca de ploaie. O iau pe mine.")
		return
	Game.flags["lei_geaca"] = true
	await _money(2, "În buzunarul gecii: doi lei, un șurub și un bon de la birt din 2019.")


func _boots() -> void:
	if Game.flags.get("lei_cizma", false):
		await say("Romică", "Cizmele de cauciuc. Le iau, că afară e noroi până la genunchi.")
		return
	Game.flags["lei_cizma"] = true
	await _money(2, "În cizma stângă: doi lei, puțin umezi. Banii de urgență.")


func _oilcloth() -> void:
	if Game.flags.get("lei_musama", false):
		await say("Romică", "Mușamaua cu mere. Mai veche decât căsnicia noastră.")
		return
	Game.flags["lei_musama"] = true
	await _money(3, "Sub mușama, sub farfuria cu mere: trei lei. Gina nu ridică niciodată farfuria.")


func _money(n: int, line: String) -> void:
	await say("Romică", line)
	Game.money += n
	Game.update_hud()
	if Game.money >= 7:
		await say("Romică", "Șapte lei. Ajunge de-o bere și de-un mic. Sau de două beri.")


func _radio() -> void:
	await say("Romică", "Radioul Gloria. Prinde doar Radio Oltenia și, când plouă, și poliția.")


func _calendar() -> void:
	await say("Romică", "Calendarul de la cooperativă. E din 2011, dar zilele se potrivesc din nou în 2022. Și în 2033.")


func _icon() -> void:
	await say("Romică", "Doamne, ajută-mă să nu mai repar nimic azi.")


func _door() -> void:
	if not _stopped:
		await say("Romică", "Întâi s-o opresc. Altfel, când mă întorc, o găsesc în curte.")
		return
	if not Game.flags.get("gina_done", false):
		await say("Romică", "Întâi să-i zic ceva Ginei. Să nu zică că plecai ca un hoț.")
		return
	if Game.money < 7:
		await say("Romică", "Fără bani la birt? Mai bine stau acasă. Am eu pe undeva vreo șapte lei ascunși...")
		return
	await say("Romică", "Plecai.")
	Game.goto("road")
