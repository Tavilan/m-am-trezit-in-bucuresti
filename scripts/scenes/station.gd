extends GameScene
## 6. Gara satului, noaptea târziu. Nepotul și gemenii îl urcă în primul tren, „să se răcorească”.

var _train_x := 700.0


func _ready() -> void:
	title = "Gara satului, noaptea târziu"
	bg_color = Color("#0c1020")
	sketch = [
		[Rect2(0, 250, 640, 110), Color("#2a2a2e"), "peronul"],
		[Rect2(30, 120, 120, 130), Color("#4a3a2a"), "halta (geam spart)"],
		[Rect2(200, 140, 50, 110), Color("#4a5a3a"), "Nelu"],
		[Rect2(320, 140, 50, 110), Color("#4a5a3a"), "Gelu"],
		[Rect2(255, 130, 60, 120), Color("#6a5a4a"), "Romică"],
		[Rect2(400, 130, 50, 120), Color("#3a4a6a"), "Marius"],
	]


func enter() -> void:
	await say("Marius", "Primul tren care vine. Te duce să te răcorești și te întorci mâine.")
	await say("Romică", "Unde... unde mă duceți, mă?")
	await say("Nelu", "La răcoare, Romică!")
	await say("Gelu", "La răcoare!")
	set_process(true)
	await Game.wait(1.6)
	await say("Romică", "Bine, bine. Da' zacusca... zacusca rămâne cu mine.")
	await say("Marius", "Rămâne, unchiule. Rămâne.")
	Game.goto("night_train", 1.2)


func _process(d: float) -> void:
	if _train_x > 0.0 and is_processing():
		_train_x = max(0.0, _train_x - d * 320.0)
		queue_redraw()


func _draw() -> void:
	super._draw()
	if _train_x < 700.0:
		draw_rect(Rect2(_train_x, 150, 640, 90), Color("#2a3a6a"))
		draw_rect(Rect2(_train_x, 170, 640, 22), Color("#c8ccd2"))
		for k in 8:
			draw_rect(Rect2(_train_x + 20 + k * 80, 172, 40, 18), Color("#e8d080"))
		draw_string(Game.font, Vector2(_train_x + 10, 230), "trenul personal", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
