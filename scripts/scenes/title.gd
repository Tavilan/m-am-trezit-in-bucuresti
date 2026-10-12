extends GameScene
## Ecranul de titlu.

func _ready() -> void:
	show_hud = false
	bg_color = Color("#0b0d16")
	hotspot("Atinge ca să începi", Rect2(0, 0, Game.W, Game.H), _start)
	hotspot("Test animație Romică", Rect2(440, 290, 190, 30), func(): Game.goto("anim_test"))


func _start() -> void:
	Game.goto("kitchen")


func _draw() -> void:
	draw_rect(Rect2(0, 0, Game.W, Game.H), bg_color)
	draw_string(Game.font, Vector2(0, 150), "M-am trezit în București", HORIZONTAL_ALIGNMENT_CENTER, Game.W, 32, Color("#ffd27a"))
	draw_string(Game.font, Vector2(0, 180), "I Woke Up in Bucharest", HORIZONTAL_ALIGNMENT_CENTER, Game.W, 16, Color(1, 1, 1, 0.6))
	draw_string(Game.font, Vector2(0, 250), "atinge ecranul ca să începi", HORIZONTAL_ALIGNMENT_CENTER, Game.W, 16, Color(1, 1, 1, 0.85))
	draw_string(Game.font, Vector2(0, 340), "prolog · versiune de test", HORIZONTAL_ALIGNMENT_CENTER, Game.W, 16, Color(1, 1, 1, 0.35))
	draw_rect(Rect2(440, 290, 190, 30), Color("#1c1826"))
	draw_rect(Rect2(440, 290, 190, 30), Color("#e8d9a8"), false, 1.0)
	draw_string(Game.font, Vector2(440, 311), "Test animație Romică", HORIZONTAL_ALIGNMENT_CENTER, 190, 16, Color("#f2e6c4"))
