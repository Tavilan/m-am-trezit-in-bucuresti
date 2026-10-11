extends GameScene
## 2. Drumul prin sat, noaptea. Birtul Unirea luminat la capătul drumului.


func _ready() -> void:
	title = "Drumul prin sat, noaptea"
	bg_color = Color("#0e1222")
	sketch = [
		[Rect2(0, 230, 640, 130), Color("#1e1c1a"), "drumul de pământ"],
		[Rect2(90, 70, 14, 170), Color("#3a3a3a"), ""],
		[Rect2(70, 60, 54, 26), Color("#8a7a3a"), "felinarul"],
		[Rect2(200, 210, 70, 40), Color("#5a4a3a"), "câinele lui Ilie"],
		[Rect2(430, 110, 170, 120), Color("#4a3a28"), "Birtul Unirea"],
		[Rect2(470, 140, 40, 30), Color("#d8b860"), ""],
	]
	hotspot("Felinarul", Rect2(70, 60, 54, 180), _lamp)
	hotspot("Câinele lui Ilie", Rect2(200, 210, 70, 40), _dog)
	hotspot("Birtul Unirea", Rect2(430, 110, 170, 120), _pub)


func enter() -> void:
	await say("Romică", "Ce noapte frumoasă... Și ce ceartă urâtă.")


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	super._draw()
	# felinarul pâlpâie (reparat de Romică acum trei ani)
	if randf() < 0.85:
		draw_circle(Vector2(97, 74), 22, Color(1, 0.85, 0.4, 0.25))


func _lamp() -> void:
	await say("Romică", "Pe ăsta l-am reparat eu acum trei ani. Ține de atunci! Mă rog... pâlpâie, dar ține.")


func _dog() -> void:
	await say("Romică", "Câinele lui Ilie. Latră la toată lumea, numai la mine nu. Ne înțelegem: suntem amândoi certați cu nevasta.")


func _pub() -> void:
	Game.goto("pub")
