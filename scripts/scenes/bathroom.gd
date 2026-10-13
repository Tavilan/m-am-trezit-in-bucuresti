extends GameScene
## 4. Baia birtului. Oglinda: prima dată când jucătorul își vede fața.

var _portrait := false
var _mirror_spr: Sprite2D
var _over: Node2D   # portretul din oglindă se desenează peste fundal (desenul scenei e sub fundal)


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
	if ResourceLoader.exists("res://art/final/romica_oglinda.png"):
		_mirror_spr = Sprite2D.new()
		_mirror_spr.texture = load("res://art/final/romica_oglinda.png")
		_mirror_spr.centered = false
		_mirror_spr.z_index = 2
		_mirror_spr.visible = false
		add_child(_mirror_spr)
	_over = Node2D.new()
	_over.z_index = 1
	_over.draw.connect(_draw_mirror)
	add_child(_over)
	hotspot("Ușa", Rect2(0, 0, 115, 360), _door)
	hotspot("Hârtia", Rect2(586, 72, 48, 70), _paper)
	hotspot("Mopul și găleata", Rect2(500, 120, 85, 240), _mop)
	hotspot("Oglinda", Rect2(205, 25, 230, 170), _mirror)
	hotspot("Chiuveta", Rect2(230, 212, 180, 70), _sink)


func enter() -> void:
	await say("Romică", "Bec chior, chiuvetă crăpată, oglindă pătată. Ca la hotel.")


func _sink() -> void:
	await cycle("sink", [
		"Curge numa' rece. Sau numa' cald. După cum îi vine.",
		"Săpunu' ăsta l-a adus Costel de la Turcia în '96. Încă nu s-a terminat, că nu-l folosește nimeni.",
	])


func _paper() -> void:
	await cycle("paper", [
		"Un sul de hârtie. Unu' singur, pentru tot satu'.",
		"E un singur sul și-i lipit cu scotch de suport. Să nu-l fure cineva.",
	])


func _mop() -> void:
	await cycle("mop", [
		"Mopu' lu' Costel. Mai bătrân ca birtu'. Și mai curat ca el.",
		"Găleata are apă de la Paști. Nu mă uit în ea.",
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
	if _mirror_spr:
		_mirror_spr.visible = true
	Game.set_hud(false)
	_over.queue_redraw()
	await Game.flash(Color.BLACK, 0.8)
	await Game.wait(2.5)               # tăcere: privirea fixă, fără nicio replică
	await say("Romică", "...")
	await Game.wait(0.8)
	await say("Romică", "Ia uite ce bărbat frumos.")
	_portrait = false
	if _mirror_spr:
		_mirror_spr.visible = false
	Game.set_hud(true)
	_over.queue_redraw()
	Game.flags["mirror_done"] = true
	await say("Romică", "Gata. Acu' pot să mă-ntorc printre oameni. Și la neamț.")


func _draw_mirror() -> void:
	if not _portrait:
		return
	if _mirror_spr:
		return   # portretul desenat e un sprite separat (vezi _ready)
	# PORTRET PROVIZORIU: Romică în oglindă, color, aproape tot ecranul, privire fixă.
	# Se înlocuiește cu ilustrația finală (pipeline hibrid).
	_over.draw_rect(Rect2(0, 0, 640, 360), Color("#3c4a46"))
	_over.draw_rect(Rect2(150, 0, 340, 360), Color("#7c8a86"))                 # rama oglinzii
	_over.draw_rect(Rect2(162, 10, 316, 340), Color("#5a6a66"))
	var skin := Color("#d8a07c")
	_over.draw_rect(Rect2(230, 60, 180, 230), skin)                            # fața
	_over.draw_rect(Rect2(215, 40, 210, 50), Color("#3a3226"))                 # căciula
	_over.draw_rect(Rect2(205, 80, 230, 14), Color("#2a241a"))
	_over.draw_rect(Rect2(262, 140, 40, 8), Color("#4a3a2a"))                  # sprâncene stufoase
	_over.draw_rect(Rect2(338, 140, 40, 8), Color("#4a3a2a"))
	_over.draw_rect(Rect2(268, 156, 28, 12), Color("#f0ece4"))                 # ochi: privire fixă
	_over.draw_rect(Rect2(344, 156, 28, 12), Color("#f0ece4"))
	_over.draw_rect(Rect2(278, 157, 8, 10), Color("#1a1a1a"))
	_over.draw_rect(Rect2(354, 157, 8, 10), Color("#1a1a1a"))
	_over.draw_rect(Rect2(268, 170, 28, 4), Color("#b07a6a"))                  # cearcăne
	_over.draw_rect(Rect2(344, 170, 28, 4), Color("#b07a6a"))
	_over.draw_rect(Rect2(306, 168, 30, 46), Color("#c8584a"))                 # nasul roșu
	_over.draw_rect(Rect2(270, 216, 100, 22), Color("#5a4a3a"))                # mustața
	_over.draw_rect(Rect2(296, 246, 50, 6), Color("#7a3a3a"))                  # gura, strânsă
	for i in 60:                                                         # barba nerasă
		_over.draw_rect(Rect2(240 + (i * 37) % 160, 236 + (i * 17) % 50, 2, 2), Color("#8a6a5a"))
	_over.draw_rect(Rect2(200, 290, 240, 60), Color("#6a5a7a"))                # puloverul pe dos (cusătura)
	_over.draw_line(Vector2(320, 290), Vector2(320, 350), Color("#9a8aaa"), 2.0)
	_over.draw_string(Game.font, Vector2(170, 344), "PORTRET PROVIZORIU", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color(1, 1, 1, 0.3))
