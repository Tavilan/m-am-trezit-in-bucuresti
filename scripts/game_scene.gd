class_name GameScene
extends Node2D
## Baza unei scene. Până vine arta finală, scena se desenează ca o schiță
## (storyboard): fundal plat, obiecte ca dreptunghiuri etichetate.
## Când apare ilustrația, se pune cu background() și schița dispare.

const HOTSPOT := preload("res://scripts/hotspot.gd")

var show_hud := true
var bg_color := Color("#141220")
var sketch: Array = []   # [Rect2, Color, "etichetă"]
var title := ""          # numele locului, desenat discret sus
var _bg: Sprite2D


func background(path: String) -> void:
	_bg = Sprite2D.new()
	_bg.texture = load(path)
	_bg.centered = false
	add_child(_bg)
	move_child(_bg, 0)
	sketch = []
	queue_redraw()


func hotspot(label: String, rect: Rect2, action: Callable) -> Control:
	var h: Control = HOTSPOT.new()
	h.label = label
	h.action = action
	h.position = rect.position
	h.size = rect.size
	add_child(h)
	return h


func say(who: String, text: String) -> void:
	await Game.say(who, text)


func _draw() -> void:
	if _bg:
		return
	draw_rect(Rect2(0, 0, Game.W, Game.H), bg_color)
	for it in sketch:
		var r: Rect2 = it[0]
		var c: Color = it[1]
		draw_rect(r, c)
		draw_rect(r, c.lightened(0.35), false, 1.0)
		if it.size() > 2 and it[2] != "":
			draw_multiline_string(Game.font, r.position + Vector2(4, 15), it[2], HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 6, 16, -1, Color(1, 1, 1, 0.8))
	if title != "":
		draw_string(Game.font, Vector2(8, Game.H - 6), title, HORIZONTAL_ALIGNMENT_LEFT, 380, 16, Color(1, 1, 1, 0.35))
	draw_string(Game.font, Vector2(Game.W - 226, Game.H - 6), "SCHIȚĂ PROVIZORIE", HORIZONTAL_ALIGNMENT_RIGHT, 220, 16, Color(1, 1, 1, 0.25))
