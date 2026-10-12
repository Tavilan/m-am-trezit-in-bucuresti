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


## Un strat de imagine (obiect, personaj static) cu marginea de jos-stânga sau centrul jos la `feet`.
## `scale_` e scara scenei: foile de personaj/obiecte au 195 cm = 300 px (vezi docs/ARTA.md).
func layer(path: String, feet: Vector2, scale_ := 1.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	s.scale = Vector2(scale_, scale_)
	s.position = (feet - Vector2(s.texture.get_width() * scale_ / 2.0, s.texture.get_height() * scale_)).round()
	add_child(s)
	return s


## Animație din art/anim/<nume>, așezată cu centrul de jos la `feet`.
func anim(anim_name: String, feet: Vector2, scale_ := 1.0) -> AnimSprite:
	var s := AnimSprite.make(anim_name)
	s.scale = Vector2(scale_, scale_)
	var fs := s.frame_size()
	s.position = (feet - Vector2(fs.x * scale_ / 2.0, fs.y * scale_)).round()
	add_child(s)
	return s


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
