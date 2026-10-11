extends GameScene
## 3. Birtul Unirea. Fost magazin de la CAP: conserve expirate, tejghea de formică, manele la televizor.
## Aici: borcanul de zacuscă (de la Tanti Veta), baia cu oglinda, apoi altercația cu nepotul.

var _fire := false


func _ready() -> void:
	title = "Birtul Unirea"
	bg_color = Color("#241c14")
	sketch = [
		[Rect2(0, 260, 640, 100), Color("#33281c"), ""],
		[Rect2(20, 40, 170, 120), Color("#4a3c2a"), "rafturi cu conserve din '98"],
		[Rect2(20, 170, 200, 70), Color("#7a6a5a"), "tejgheaua de formică"],
		[Rect2(90, 110, 50, 60), Color("#6a4a3a"), "Costel"],
		[Rect2(230, 40, 90, 64), Color("#22303a"), "televizorul (manele)"],
		[Rect2(330, 150, 120, 110), Color("#4a5a3a"), "Nelu și Gelu"],
		[Rect2(470, 130, 70, 130), Color("#3a4a6a"), "Marius, nepotul"],
		[Rect2(250, 170, 60, 90), Color("#6a4a5a"), "Tanti Veta"],
		[Rect2(560, 40, 70, 210), Color("#3a3028"), "ușa băii"],
		[Rect2(240, 115, 70, 40), Color("#9aa8b0"), "frigiderul de bere"],
	]
	hotspot("Costel, birtașul", Rect2(20, 110, 200, 130), _costel)
	hotspot("Rafturile", Rect2(20, 40, 170, 68), _shelves)
	hotspot("Televizorul", Rect2(230, 40, 90, 64), _tv)
	hotspot("Nelu și Gelu", Rect2(330, 150, 120, 110), _twins)
	hotspot("Marius, nepotul", Rect2(470, 130, 70, 130), _marius)
	hotspot("Tanti Veta", Rect2(250, 170, 60, 90), _veta)
	hotspot("Ușa băii", Rect2(560, 40, 70, 210), _bathroom)
	hotspot("Frigiderul de bere", Rect2(240, 115, 70, 40), _fridge)
	_fire = Game.flags.get("fire", false)


func enter() -> void:
	if _fire:
		await _after_fire()
	elif Game.flags.get("mirror_done", false):
		if not Game.has_zacusca:
			await say("Tanti Veta", "Romică! Stai, maică, că era să uit.")
			await _give_zacusca()
	elif not Game.flags.get("pub_seen", false):
		Game.flags["pub_seen"] = true
		await say("Costel", "Romică! Ce-ți dau?")
		await say("Romică", "Ce dai tu mai tare, Costele. Azi am nevoie.")


func _process(_d: float) -> void:
	if _fire:
		queue_redraw()


func _draw() -> void:
	super._draw()
	if _fire:
		# jumătatea din dreapta a birtului arde (schiță)
		for i in 26:
			var x := 320.0 + randf() * 320.0
			var h := 40.0 + randf() * 160.0
			draw_rect(Rect2(x, 300 - h, 10 + randf() * 14, h), Color(1, 0.35 + randf() * 0.4, 0.05, 0.35))
		draw_rect(Rect2(320, 0, 320, 360), Color(1, 0.4, 0.1, 0.12 + randf() * 0.06))


func _costel() -> void:
	if _fire:
		await say("Costel", "Nu-mi mai vorbi, Romică!")
		return
	await say("Costel", "Încă una?")
	await say("Romică", "Una mică. Mică-mică. Cât degetul.")
	await say("Romică", "...Degetul mare.")


func _shelves() -> void:
	await say("Romică", "Conserve de pește din '98. Peștele e mai bătrân decât nepotu-meu.")


func _tv() -> void:
	await say("Romică", "Televizorul de la CAP. Prinde trei canale, și două sunt același.")


func _twins() -> void:
	if Game.flags.get("mirror_done", false):
		await say("Nelu", "Romică, du-te la nepotu-tău, că zice ceva de tine.")
		await say("Gelu", "Zice ceva de tine!")
		return
	await say("Nelu", "Romică, ne repari și nouă televizorul?")
	await say("Gelu", "Că al nostru prinde numai manele.")
	await say("Romică", "Așa e făcut, mă. Să prindă numai manele.")


func _veta() -> void:
	if Game.has_zacusca:
		await say("Tanti Veta", "Ai grijă de borcan, Romică. E de la soră-mea, din Craiova.")
		return
	await _give_zacusca()


func _give_zacusca() -> void:
	await say("Tanti Veta", "Romică, maică, ia zacusca asta de la mine și du-i-o Ginei. Cu zacuscă se împacă orice ceartă.")
	Game.has_zacusca = true
	Game.update_hud()
	await say("Romică", "Mulțumesc, tanti Veta. O țin la mine ca pe ochii din cap.")


func _fridge() -> void:
	if Game.flags.get("mirror_done", false):
		await say("Romică", "Frigiderul... are o problemă. Și eu am o soluție. Dar întâi să-l aud pe nepotu-meu ce zice.")
	else:
		await say("Costel", "Nu mai răcește de-o săptămână. Berea e caldă ca ceaiul.")


func _bathroom() -> void:
	if Game.flags.get("mirror_done", false):
		await say("Romică", "Mă spălai deja o dată azi. Ajunge.")
		return
	Game.goto("bathroom")


func _marius() -> void:
	if not Game.flags.get("mirror_done", false):
		await say("Romică", "Marius, nepotu-meu, venit din Germania. Mă uit la el și nu-l recunosc...")
		await say("Romică", "Ia să mă duc întâi să mă spăl pe față.")
		return
	await say("Marius", "Unchiule, tot cu sârma și banda izolatoare? În Germania asta se cheamă pericol public.")
	await say("Nelu", "Hă-hă! Meșter de sârmă!")
	await say("Gelu", "Meșter de sârmă!")
	await say("Romică", "Meșter de sârmă, ziseși?")
	await say("Romică", "Costele! Ce are frigiderul de bere?")
	await say("Costel", "Nu mai răcește de-o săptămână.")
	await say("Romică", "Uitați-vă și învățați. Arătai eu și Germaniei.")
	Game.goto("wires")


func _after_fire() -> void:
	await Game.shake(5.0, 0.6)
	await say("Costel", "Ardeee! Mi-ai ars birtul, Romică!")
	await say("Romică", "Jumătate! Jumătate e întreagă!")
	await say("Marius", "Gata, unchiule. Mergi să te răcorești.")
	await say("Nelu", "Hai, Romică, hai cu noi.")
	await say("Gelu", "Hai cu noi!")
	Game.goto("station")
