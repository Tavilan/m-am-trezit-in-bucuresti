extends GameScene
## 4. Baia birtului. Oglinda: prima dată când jucătorul își vede fața.

var _portrait := false


func _ready() -> void:
	title = "Baia birtului"
	music = "res://audio/manele_tv.ogg"   # se aude prin ușă, înfundat
	radio = true
	if ResourceLoader.exists("res://art/final/baie_fundal.png"):
		background("res://art/final/baie_fundal.png")
	else:
		bg_color = Color("#1e2420")
		sketch = [
			[Rect2(0, 270, 640, 90), Color("#2a302a"), "gresie spartă"],
			[Rect2(250, 40, 140, 150), Color("#8a9a9a"), "oglinda pătată"],
			[Rect2(240, 200, 160, 60), Color("#c8c8c0"), "chiuveta crăpată"],
			[Rect2(20, 40, 110, 230), Color("#3a3028"), "ușa"],
		]
	hotspot("Oglinda", Rect2(250, 40, 140, 150), _mirror)
	hotspot("Chiuveta", Rect2(240, 200, 160, 60), _sink)
	hotspot("Ușa", Rect2(20, 40, 110, 230), _door)


func enter() -> void:
	await say("Romică", "Bec chior, chiuvetă crăpată, oglindă pătată. Ca la hotel.")


func _sink() -> void:
	await cycle("sink", [
		"Curge numa' rece. Sau numa' cald. După cum îi vine.",
		"Săpunu' ăsta l-a adus Costel de la Turcia în '96. Încă nu s-a terminat, că nu-l folosește nimeni.",
	])


func _door() -> void:
	if not Game.flags.get("mirror_done", false):
		await say("Romică", "Venii să mă spăl pe față. Măcar să mă uit în oglindă.")
		return
	Game.goto("pub")


func _mirror() -> void:
	if Game.flags.get("mirror_done", false):
		await cycle("mirror_again", [
			"Tot ăla e.",
			"Nu mă mai uit. O dată pe seară ajunge.",
		])
		return
	await say("Romică", "Ia să mă spăl pe față...")
	_portrait = true
	Game.set_hud(false)
	queue_redraw()
	await Game.flash(Color.BLACK, 0.8)
	await Game.wait(2.5)               # tăcere: privirea fixă, fără nicio replică
	await say("Romică", "...")
	await Game.wait(0.8)
	await say("Romică", "Ia uite ce bărbat frumos.")
	_portrait = false
	Game.set_hud(true)
	queue_redraw()
	Game.flags["mirror_done"] = true
	await say("Romică", "Gata. Acu' pot să mă-ntorc printre oameni. Și la neamț.")


func _draw() -> void:
	if not _portrait:
		super._draw()
		return
	if ResourceLoader.exists("res://art/final/romica_oglinda.png"):
		draw_texture(load("res://art/final/romica_oglinda.png"), Vector2.ZERO)
		return
	# PORTRET PROVIZORIU: Romică în oglindă, color, aproape tot ecranul, privire fixă.
	# Se înlocuiește cu ilustrația finală (pipeline hibrid).
	draw_rect(Rect2(0, 0, 640, 360), Color("#3c4a46"))
	draw_rect(Rect2(150, 0, 340, 360), Color("#7c8a86"))                 # rama oglinzii
	draw_rect(Rect2(162, 10, 316, 340), Color("#5a6a66"))
	var skin := Color("#d8a07c")
	draw_rect(Rect2(230, 60, 180, 230), skin)                            # fața
	draw_rect(Rect2(215, 40, 210, 50), Color("#3a3226"))                 # căciula
	draw_rect(Rect2(205, 80, 230, 14), Color("#2a241a"))
	draw_rect(Rect2(262, 140, 40, 8), Color("#4a3a2a"))                  # sprâncene stufoase
	draw_rect(Rect2(338, 140, 40, 8), Color("#4a3a2a"))
	draw_rect(Rect2(268, 156, 28, 12), Color("#f0ece4"))                 # ochi: privire fixă
	draw_rect(Rect2(344, 156, 28, 12), Color("#f0ece4"))
	draw_rect(Rect2(278, 157, 8, 10), Color("#1a1a1a"))
	draw_rect(Rect2(354, 157, 8, 10), Color("#1a1a1a"))
	draw_rect(Rect2(268, 170, 28, 4), Color("#b07a6a"))                  # cearcăne
	draw_rect(Rect2(344, 170, 28, 4), Color("#b07a6a"))
	draw_rect(Rect2(306, 168, 30, 46), Color("#c8584a"))                 # nasul roșu
	draw_rect(Rect2(270, 216, 100, 22), Color("#5a4a3a"))                # mustața
	draw_rect(Rect2(296, 246, 50, 6), Color("#7a3a3a"))                  # gura, strânsă
	for i in 60:                                                         # barba nerasă
		draw_rect(Rect2(240 + (i * 37) % 160, 236 + (i * 17) % 50, 2, 2), Color("#8a6a5a"))
	draw_rect(Rect2(200, 290, 240, 60), Color("#6a5a7a"))                # puloverul pe dos (cusătura)
	draw_line(Vector2(320, 290), Vector2(320, 350), Color("#9a8aaa"), 2.0)
	draw_string(Game.font, Vector2(170, 344), "PORTRET PROVIZORIU", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color(1, 1, 1, 0.3))
