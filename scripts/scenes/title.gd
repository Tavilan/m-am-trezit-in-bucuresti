extends GameScene
## Ecranul de titlu.

func _ready() -> void:
	show_hud = false
	bg_color = Color("#0b0d16")
	hotspot("Atinge ca să începi", Rect2(0, 0, Game.W, Game.H), _start)


func _start() -> void:
	Game.goto("kitchen")


func _draw() -> void:
	draw_rect(Rect2(0, 0, Game.W, Game.H), bg_color)
	draw_string(Game.font, Vector2(0, 150), "M-am trezit în București", HORIZONTAL_ALIGNMENT_CENTER, Game.W, 32, Color("#ffd27a"))
	draw_string(Game.font, Vector2(0, 180), "I Woke Up in Bucharest", HORIZONTAL_ALIGNMENT_CENTER, Game.W, Game.FS, Color(1, 1, 1, 0.6))
	draw_string(Game.font, Vector2(0, 250), "atinge ecranul ca să începi", HORIZONTAL_ALIGNMENT_CENTER, Game.W, Game.FS, Color(1, 1, 1, 0.85))
	draw_string(Game.font, Vector2(0, 340), "prolog · versiune de test", HORIZONTAL_ALIGNMENT_CENTER, Game.W, Game.FS, Color(1, 1, 1, 0.35))
