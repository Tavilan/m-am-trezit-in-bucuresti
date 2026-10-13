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
const SOCKET := Rect2(262, 218, 8, 10)   # priza de pe perete, în dreapta mașinii (departe de cizme)
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
	music = "res://audio/lautareasca_radio.ogg"   # vine de la radioul de pe raft
	radio = true
	ambience_db = -10.0
	ambience = "res://audio/masina_spalat.ogg"   # mașina se aude peste radio (sugestiv, nu realist); ploaia nu
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
	hotspot("Priza", SOCKET.grow(8), _socket)
	_over = Node2D.new()
	_over.draw.connect(_draw_over)
	add_child(_over)
	_glass = (load("res://art/final/bucatarie_geam_masca.png") as Texture2D).get_image()
	for i in 60:
		_rain.append(WINDOW.position + Vector2(randf_range(0, WINDOW.size.x), randf_range(0, WINDOW.size.y)))
	for i in 55:
		_drops.append([WINDOW.position + Vector2(randi_range(0, int(WINDOW.size.x)), randi_range(0, int(WINDOW.size.y))), 0.0])


func enter() -> void:
	await say("Gina", "Romicăăă! Vino-ncoa' să vezi ce făcuși, bă!")
	await say("Romică", "Ce făcui, fă? O reparai.")
	await say("Gina", "O reparași... Uite-o, mă, cum umblă prin casă ca vaca! Mi-a rupt linoleumu'!")
	await say("Gina", "Oprește-o, că dacă iese pe ușă, după ea pleci!")


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
		var back := _washer.position + Vector2(_washer.texture.get_width() * 0.85, _washer.texture.get_height() * 0.5)
		var plug := SOCKET.get_center()
		var mid := (plug + back) / 2.0 + Vector2(0, 14)
		_under.draw_polyline(PackedVector2Array([plug, mid, back]), Color(0.12, 0.1, 0.1), 2.0)
	else:
		_under.draw_line(Vector2(SOCKET.position.x - 2, SOCKET.end.y + 4), Vector2(SOCKET.position.x - 14, SOCKET.end.y + 14), Color(0.12, 0.1, 0.1), 2.0)
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
		await cycle("gina_after", [
			[["Gina", "Ce mai stai? Ți-am zis tot ce-aveam de zis."]],
			[["Gina", "Nu mă lua cu «Gino». Du-te."]],
			[["Gina", "Romică, nu mă scoate din sărite, că pun mâna pe făcăleț."]],
			[["Gina", "..."]],
		])
		return
	if not _stopped:
		await cycle("gina_busy", [
			[["Gina", "N-auzi, bă? Oprește-o odată!"]],
			[["Gina", "Io nu vorbesc cu tine până nu tace drăcia aia."]],
			[["Gina", "Mă bagi în mormânt cu sârmele tale, Romică. În mormânt!"]],
		])
		return
	await say("Gina", "Gata. Acu' stai locului și ascultă la mine.")
	await say("Gina", "Treizeci de ani, Romică. Treizeci de ani de sârmă și de bandă.")
	await say("Gina", "La toată lumea repari. La Ilie, la Costel, la popa. Pe gratis, pe-o țuică.")
	await say("Gina", "Și-n casa mea? Robinetu' curge de la Paști. Ușa de la cotineț o țin cu cărămida.")
	var a := await Game.choose(["„Las', fă, că le fac mâine.”", "„Da' ce, io stau degeaba? Muncesc toată ziua!”", "„Ce vrei, să iau una nouă? Cu ce bani?”"])
	match a:
		0:
			await say("Romică", "Las', fă, că le fac mâine.")
			await say("Gina", "Mâine. De când te știu, mâine. Pe cruce o să-ți scrie: «Le face mâine».")
		1:
			await say("Romică", "Da' ce, io stau degeaba? Muncesc toată ziua!")
			await say("Gina", "Muncești pe țuică, Romică. Țuica n-o pun în oală.")
		2:
			await say("Romică", "Ce vrei, fă, să iau una nouă? Cu ce bani?")
			await say("Gina", "Cu ăia pe care-i lași la Costel. Socotește de la Crăciun încoace. Luam două mașini.")
	await say("Gina", "Și-a venit și Marius al lu' soră-ta din Germania. De la prânz stă la birt și se laudă.")
	await say("Gina", "Mi-a zis soră-ta că-i e rușine să vină pe la noi. Rușine, auzi? Cu noi!")
	var b := await Game.choose(["„Lasă-l, fă. L-am învățat io tot ce știe.”", "„Mă duc până la birt. Un sfert de oră.”"])
	if b == 0:
		await say("Romică", "Lasă-l, fă. L-am învățat io tot ce știe.")
		await say("Gina", "Asta-i problema, Romică. Asta-i problema.")
		await say("Romică", "Mă duc până la birt. Să-l văd și io pe neamțu' ăsta.")
	else:
		await say("Romică", "Mă duc până la birt. Un sfert de oră.")
		await say("Gina", "Un sfert de oră. Ca la nunta lu' Fănel, când te-am cules din șanț la patru dimineața.")
	await say("Gina", "Du-te. Du-te, că nu te mai pot vedea în ochi în seara asta.")
	await say("Gina", "Și să nu-mi umbli la bani! Ăia de pe dulap îs de lemne.")
	var c := await Game.choose(["„Care bani, fă? N-am un leu.”", "„O bere și viu.”", "„Ține-i tu, să nu-i beau.”"])
	match c:
		0:
			await say("Romică", "Care bani, fă? N-am un leu.")
			await say("Gina", "Las' că știu io. Prin geacă, prin cizmă, sub mușama... Șoarecii din casa asta-s mai bogați ca mine.")
		1:
			await say("Romică", "O bere și viu.")
			await say("Gina", "O bere. Ultima oară când ziseși «o bere» veniși cu poarta lu' Ilie-n spate.")
		2:
			await say("Romică", "Ține-i tu, să nu-i beau.")
			await say("Gina", "Să-i țin io? Ca mâine să mi-i ceri înapoi plângând? Ține-i tu, că-s ai tăi. Ce mai e din ei.")
			Game.flags["gina_soft"] = true
	await say("Gina", "Și nu mă trezi când vii, că nu-ți deschid.")
	Game.flags["gina_done"] = true


func _washer_talk() -> void:
	if _stopped:
		await cycle("washer_off", [
			"Stă. Mâine o leg de calorifer, să nu mai umble.",
			"Știu ce are. Tamburu' e prea vesel.",
			"N-o mai ating azi. Jur pe icoană.",
		])
		return
	_shake = 3.0
	if not _plug_game:
		await say("Romică", "Sârmă de doi milimetri, strânsă ca la carte. Nu-i de la sârmă, e de la centrifugă.")
		_shake = 1.0
		await say("Romică", "Ștecheru' e-n priza din dreapta ei. Trebe să-l smulg când pleacă de lângă perete.")
		_plug_game = true
		_walk_amp = 46.0
		return
	await cycle("washer_on", [
		"Merge, fă! Ziceai că nu merge. Uite cum merge.",
		"Dacă-i pun și roți, se duce singură la târg.",
		"Priza, Romică. Priza din dreapta.",
	])
	_shake = 1.0


## Minijocul: scoți ștecherul doar când mașina s-a îndepărtat de priză; altfel te lovește.
func _socket() -> void:
	if _stopped:
		await cycle("socket_off", [
			"Priza. O pusei io în '94. Ține și-acum.",
			"Are și împământare. Adică are o sârmă la țeava de la chiuvetă.",
		])
		return
	var covered := _washer.position.x < SOCKET.end.x + 4 and _washer.position.x + _washer.texture.get_width() > SOCKET.position.x - 4
	if covered:
		Game.shake(4.0, 0.35)
		await say("Romică", ["Au! Mă pocni-n deget, fir-ar a dracu' de mașină!", "Stai, fă, că nu-ți fur nimic!", "Futu-i... Așteaptă să plece de lângă perete, Romică."].pick_random())
		_plug_game = true
		_walk_amp = 46.0
		return
	_stopped = true
	_shake = 0.0
	Game.set_audio(music, "", true)   # mașina tace, rămâne radioul
	Game.shake(2.0, 0.2)
	await say("Romică", "Gata! Tăcu.")
	await say("Gina", "Bravo. Ai tras de fir. Asta știe și Mioara, și ea n-a făcut nici patru clase.")
	await say("Romică", "Las', fă, că merge și oprită.")


func _coat() -> void:
	if not Game.flags.get("lei_geaca", false):
		Game.flags["lei_geaca"] = true
		await _money(2, "În buzunaru' de la geacă: doi lei, un șurub și-un bon de la Costel din 2019.")
		return
	await cycle("coat", [
		"Geaca de ploaie. Pute a motorină, da' ține de ploaie.",
		"În celălalt buzunar e o bomboană lipită de căptușeală. O las acolo, e de rezervă.",
	])


func _boots() -> void:
	if not Game.flags.get("lei_cizma", false):
		Game.flags["lei_cizma"] = true
		await _money(2, "În cizma stângă: doi lei, cam umezi. Banii de urgență.")
		return
	await cycle("boots", [
		"Cizmele de cauciuc. Afară e glod până la genunchi.",
		"Dreapta are o gaură. O peticii cu cameră de bicicletă. Ține.",
	])


func _oilcloth() -> void:
	if not Game.flags.get("lei_musama", false):
		Game.flags["lei_musama"] = true
		await _money(3, "Sub mușama, sub farfuria cu mere: trei lei. Gina nu mișcă farfuria niciodată, că-i de la mă-sa.")
		return
	await cycle("oilcloth", [
		"Mușamaua cu mere. E mai bătrână ca însurătoarea noastră.",
		"Arsura de-aici e de la ciocanu' de lipit. Nu zic nimic, că nu m-a întrebat nimeni.",
	])


func _money(n: int, line: String) -> void:
	await say("Romică", line)
	Game.money += n
	Game.update_hud()
	if Game.money >= 7:
		await say("Romică", "Șapte lei. O bere și-un mic. Sau două beri și niciun mic.")


func _radio() -> void:
	await cycle("radio", [
		"Radioul Gloria. Prinde numa' Radio Oltenia și, când plouă, și stația de la poliție.",
		"Lăutarii ăștia cântă de când eram io copil. Tot aceeași cântare, da' tot frumoasă.",
		"Dacă-i dai una în partea stângă, prinde și Craiova.",
	])


func _calendar() -> void:
	await cycle("calendar", [
		"Calendaru' de la cooperativă, din 2011. Zilele cad ca-n 2022. Și ca-n 2033, deci mai ține.",
		"Pe noiembrie scrisei cu pixu': «Ilie, 20 lei». Nu mai știu dacă-i dau io lui sau el mie.",
		"Gina a încercuit ziua de 14. Nu știu ce-i pe 14. Mai bine nu întreb.",
	])


func _icon() -> void:
	await cycle("icon", [
		"Doamne, ajută-mă să nu mai repar nimic azi.",
		"Candela o umplui cu ulei de la mașină. Arde mai frumos.",
		"Sfântu' Nicolae, de la mama Ginei. Tot ce-i frumos în casa asta e de la mama Ginei. Zice Gina.",
	])


func _door() -> void:
	if not _stopped:
		await say("Romică", "Întâi o opresc. Altfel, când mă-ntorc, o găsesc la Ilie-n curte.")
		return
	if not Game.flags.get("gina_done", false):
		await say("Romică", "Stai, că trebe să-i zic ceva Ginei. Să nu zică c-o tulii ca hoții.")
		return
	if Game.money < 7:
		await say("Romică", "La birt fără bani? Mai bine stau acasă să mă certe. Șapte lei am pe undeva ascunși, numa' să-i găsesc...")
		return
	await say("Romică", "Plecai.")
	Game.goto("road")
