extends Control
## Zonă pe care se poate da click/tap. Arată numele la hover și se evidențiază la butonul „?”.

var label := ""
var action: Callable
## Evidențierea urmează forma lucrului, nu un chenar: fie conturul desenat pe fundal (poligon în
## coordonatele scenei, din <fundal>_contur.json), fie marginea unui sprite (personaj, mașina de spălat).
var shape := PackedVector2Array()
var target: CanvasItem
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


const OUTLINE := Color(1.0, 0.86, 0.55)


func _draw() -> void:
	var a := 0.0
	if (_hover and not Game.busy) or _flash > 0.0:
		a = 0.85 if _hover else clampf(_flash, 0.0, 1.0) * 0.85
	if target and is_instance_valid(target):
		var m := target.material as ShaderMaterial
		if m and m.shader and m.shader.resource_path.ends_with("scene_light.gdshader"):
			m.set_shader_parameter("outline", a)
		return
	if a <= 0.0 or shape.is_empty():
		return   # fără contur cunoscut nu desenăm nimic (niciodată chenar)
	var pts := PackedVector2Array()
	for p in shape:
		pts.append(p - global_position)
	pts.append(pts[0])
	draw_polyline(pts, Color(0, 0, 0, 0.35 * a), 3.0)
	draw_polyline(pts, Color(OUTLINE, a), 1.0)
