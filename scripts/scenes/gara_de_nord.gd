extends GameScene
## 8. Gara de Nord, dimineața. Bliț-ul unui turist. „…am ajuns în București.”


func _ready() -> void:
	title = "Gara de Nord, dimineața"
	bg_color = Color("#1a2030")
	sketch = [
		[Rect2(0, 250, 640, 110), Color("#4a4a52"), "peronul"],
		[Rect2(0, 0, 640, 60), Color("#3a2c22"), "copertina de lemn"],
		[Rect2(120, 60, 18, 190), Color("#7a8a9a"), ""],
		[Rect2(480, 60, 18, 190), Color("#7a8a9a"), ""],
		[Rect2(330, 110, 60, 140), Color("#5a7a5a"), "turistul"],
	]


func enter() -> void:
	await Game.flash(Color.WHITE, 0.9)
	await say("Turist", "Wow. Very authentic!")
	await Game.flash(Color.WHITE, 0.6)
	await say("Romică", "Ce... unde... Gino?")
	await say("Romică", "Mă... ăsta nu e satul meu.")
	await Game.wait(0.6)
	await say("Romică", "...am ajuns în București.")
	await say("Romică", "Șapte lei și un borcan de zacuscă. Bun. De aici se poate.")
	Game.goto("the_end", 1.0)
