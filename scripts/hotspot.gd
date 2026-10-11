extends Control
## Zonă pe care se poate da click/tap. Arată numele la hover și se evidențiază la butonul „?”.

var label := ""
var action: Callable
var _hover := false
var _flash := 0.0


func _ready() -> void:
	add_to_group("hotspots")
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func():
		_hover = true
		Game.show_tip(label, get_global_rect())
		queue_redraw())
	mouse_exited.connect(func():
		_hover = false
		Game.hide_tip()
		queue_redraw())


func _gui_input(e: InputEvent) -> void:
	# doar InputEventMouseButton: tap-ul e emulat ca click (vezi README)
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		Game.interact(action)


func flash() -> void:
	if not is_visible_in_tree():
		return
	_flash = 1.6
	Game.show_tip(label, get_global_rect())
	set_process(true)


func _process(d: float) -> void:
	if _flash > 0.0:
		_flash -= d
		queue_redraw()
		if _flash <= 0.0:
			Game.hide_tip()
	else:
		set_process(false)


func _draw() -> void:
	if (_hover and not Game.busy) or _flash > 0.0:
		var a: float = 1.0 if _hover else clampf(_flash, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.82, 0.48, 0.9 * a), false, 1.0)
