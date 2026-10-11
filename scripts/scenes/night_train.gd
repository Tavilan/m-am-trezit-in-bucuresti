extends GameScene
## 7. Negru. Trenul merge ore întregi.


func _ready() -> void:
	show_hud = false
	bg_color = Color.BLACK


func _draw() -> void:
	draw_rect(Rect2(0, 0, Game.W, Game.H), Color.BLACK)


func enter() -> void:
	for line in ["ceaf-ceaf... ceaf-ceaf...", "Craiova.", "Slatina.", "Pitești.", "ceaf-ceaf... ceaf-ceaf...", "(ore întregi mai târziu)"]:
		await say("", line)
	Game.goto("gara_de_nord", 0.2)
