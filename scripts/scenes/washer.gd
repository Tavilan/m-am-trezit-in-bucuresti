extends Node2D
## Mașina de spălat legată cu sârmă, care centrifughează și se plimbă (schiță animată).

var _t := 0.0
var _home := Vector2.ZERO


func _ready() -> void:
	_home = position


func _process(d: float) -> void:
	_t += d
	position = _home + Vector2(sin(_t * 0.9) * 14.0 + randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 80, 80), Color("#d8d4cc"))
	draw_rect(Rect2(0, 0, 80, 80), Color("#f4f0e8"), false, 1.0)
	draw_circle(Vector2(40, 46), 24, Color("#3a4a5a"))
	draw_circle(Vector2(40, 46), 18, Color("#5a7a9a").lerp(Color.WHITE, 0.3 + 0.2 * sin(_t * 20.0)))
	# sârma: două ture în jurul mașinii
	draw_line(Vector2(-3, 20), Vector2(83, 26), Color("#b07a3a"), 2.0)
	draw_line(Vector2(-3, 62), Vector2(83, 56), Color("#b07a3a"), 2.0)
	draw_string(Game.font, Vector2(0, -4), "mașina de spălat", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#222"))
