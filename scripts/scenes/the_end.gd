extends GameScene
## Sfârșitul prologului (versiunea de test).


func _ready() -> void:
	show_hud = false
	bg_color = Color("#0b0d16")
	hotspot("Joacă din nou", Rect2(220, 250, 200, 40), func(): Game.start())


func _draw() -> void:
	draw_rect(Rect2(0, 0, Game.W, Game.H), bg_color)
	draw_string(Game.font, Vector2(0, 120), "Sfârșitul prologului", HORIZONTAL_ALIGNMENT_CENTER, Game.W, 24, Color("#ffd27a"))
	draw_string(Game.font, Vector2(0, 160), "Versiune de test: schițe provizorii, arta finală vine ulterior.", HORIZONTAL_ALIGNMENT_CENTER, Game.W, Game.FS, Color(1, 1, 1, 0.6))
	draw_string(Game.font, Vector2(0, 200), "Urmează: Bucureștiul.", HORIZONTAL_ALIGNMENT_CENTER, Game.W, Game.FS, Color(1, 1, 1, 0.85))
	draw_rect(Rect2(220, 250, 200, 40), Color("#1c1826"))
	draw_rect(Rect2(220, 250, 200, 40), Color("#e8d9a8"), false, 1.0)
	draw_string(Game.font, Vector2(220, 276), "Joacă din nou", HORIZONTAL_ALIGNMENT_CENTER, 200, Game.FS, Color("#f2e6c4"))
