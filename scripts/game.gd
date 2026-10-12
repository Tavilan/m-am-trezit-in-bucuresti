extends Node
## Starea jocului și interfața comună: dialoguri, alegeri, tranziții, HUD.
## Autoload „Game”. Scenele cheamă Game.say(), Game.choose(), Game.goto().

const W := 640
const H := 360
const FONT_PATH := "res://art/fonts/PixelifySans.ttf"

# ---- starea jocului
var money := 7
var has_zacusca := false
var flags := {}

# ---- interfață
var font: FontFile
var world: Node2D
var busy := false
var _blocker: Control
var _dlg: PanelContainer
var _dlg_name: Label
var _dlg_text: Label
var _dlg_more: Label
var _choices: VBoxContainer
var _fade: ColorRect
var _hud: Label
var _tip: Label
var _rotate: Control
var _hint_btn: Button
var _typing: Tween
var _portrait_root: Control
var _portrait: AnimSprite
var _portrait_who := ""
## numele din dialog -> numele animației/portretului (art/anim/<x>_vorbit, art/final/<x>_portret.png)
const PORTRAITS := {"Romică": "romica", "Gina": "gina", "Marius": "marius", "Costel": "costel",
	"Tanti Mioara": "mioara", "Nelu": "nelu", "Gelu": "gelu", "Turistul": "turist"}
## cine apare în stânga (Romică, eroul); ceilalți în dreapta
const PORTRAIT_LEFT := ["Romică"]
var hud_on := true
var _transitioning := false

signal advanced
signal chosen(index: int)


func _ready() -> void:
	font = load(FONT_PATH)
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.hinting = TextServer.HINTING_NONE
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	_build_ui()


func _process(_d: float) -> void:
	var s := DisplayServer.window_get_size()
	_rotate.visible = s.y > s.x


# ================================================================ UI
func _theme() -> Theme:
	var t := Theme.new()
	t.default_font = font
	t.default_font_size = 16
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#0c0a12e8")
	box.border_color = Color("#e8d9a8")
	box.set_border_width_all(1)
	box.set_content_margin_all(8)
	t.set_stylebox("panel", "PanelContainer", box)
	for st in ["normal", "hover", "pressed", "focus"]:
		var b := StyleBoxFlat.new()
		b.bg_color = Color("#1c1826") if st == "normal" else Color("#3a2e1a")
		b.border_color = Color("#e8d9a8") if st != "normal" else Color("#7a6c50")
		b.set_border_width_all(1)
		b.set_content_margin_all(6)
		t.set_stylebox(st, "Button", b)
	t.set_color("font_color", "Button", Color("#f2e6c4"))
	t.set_color("font_hover_color", "Button", Color("#ffd27a"))
	t.set_color("font_color", "Label", Color("#f2e6c4"))
	return t


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var root := Control.new()
	root.size = Vector2(W, H)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _theme()
	layer.add_child(root)

	_hud = Label.new()
	_hud.position = Vector2(6, 4)
	_hud.add_theme_color_override("font_shadow_color", Color.BLACK)
	_hud.add_theme_constant_override("shadow_offset_x", 1)
	_hud.add_theme_constant_override("shadow_offset_y", 1)
	root.add_child(_hud)
	update_hud()

	_tip = Label.new()
	_tip.visible = false
	_tip.add_theme_color_override("font_color", Color("#ffd27a"))
	_tip.add_theme_color_override("font_shadow_color", Color.BLACK)
	_tip.add_theme_constant_override("shadow_offset_x", 1)
	_tip.add_theme_constant_override("shadow_offset_y", 1)
	root.add_child(_tip)

	_hint_btn = Button.new()
	_hint_btn.text = "?"
	_hint_btn.position = Vector2(W - 30, 4)
	_hint_btn.size = Vector2(24, 24)
	_hint_btn.tooltip_text = "Arată ce se poate atinge"
	_hint_btn.pressed.connect(_flash_hotspots)
	root.add_child(_hint_btn)

	# blocker: în timpul dialogurilor prinde orice atingere și avansează textul
	_blocker = Control.new()
	_blocker.size = Vector2(W, H)
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_blocker.visible = false
	_blocker.gui_input.connect(_on_blocker_input)
	root.add_child(_blocker)

	# portretul mare al celui care vorbește, în spatele casetei de text
	_portrait_root = Control.new()
	_portrait_root.size = Vector2(W, H)
	_portrait_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_root.visible = false
	root.add_child(_portrait_root)

	_dlg = PanelContainer.new()
	_dlg.position = Vector2(12, H - 92)
	_dlg.size = Vector2(W - 24, 82)
	_dlg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dlg.visible = false
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dlg.add_child(v)
	_dlg_name = Label.new()
	_dlg_name.add_theme_color_override("font_color", Color("#ffd27a"))
	v.add_child(_dlg_name)
	_dlg_text = Label.new()
	_dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dlg_text.custom_minimum_size = Vector2(W - 44, 0)
	v.add_child(_dlg_text)
	root.add_child(_dlg)
	_dlg_more = Label.new()
	_dlg_more.text = ">"
	_dlg_more.position = Vector2(W - 30, H - 26)
	_dlg_more.visible = false
	root.add_child(_dlg_more)

	_choices = VBoxContainer.new()
	_choices.position = Vector2(60, 110)
	_choices.size = Vector2(W - 120, 0)
	_choices.add_theme_constant_override("separation", 6)
	_choices.visible = false
	root.add_child(_choices)

	_fade = ColorRect.new()
	_fade.size = Vector2(W, H)
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_fade)

	_rotate = ColorRect.new()
	(_rotate as ColorRect).color = Color("#0b0d16")
	_rotate.size = Vector2(W, H)
	_rotate.mouse_filter = Control.MOUSE_FILTER_STOP
	var rl := Label.new()
	rl.text = "Întoarce telefonul pe orizontală"
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rl.size = Vector2(W, 40)
	rl.position = Vector2(0, H / 2 - 20)
	_rotate.add_child(rl)
	_rotate.visible = false
	root.add_child(_rotate)


func update_hud() -> void:
	var t := "%d lei" % money
	if has_zacusca:
		t += "   ·   borcan de zacuscă"
	_hud.text = t


func set_hud(on: bool) -> void:
	hud_on = on
	_hud.visible = on
	_hint_btn.visible = on and not busy


func show_tip(text: String, at: Rect2) -> void:
	if busy:
		return
	_tip.text = text
	_tip.visible = true
	_tip.reset_size()
	var x: float = clamp(at.position.x + at.size.x / 2 - _tip.size.x / 2, 4, W - _tip.size.x - 4)
	var y: float = at.position.y - _tip.size.y - 2
	if y < 24:
		y = at.position.y + at.size.y + 2
	_tip.position = Vector2(x, y)


func hide_tip() -> void:
	_tip.visible = false


func _flash_hotspots() -> void:
	get_tree().call_group("hotspots", "flash")


# ================================================================ dialog
func _on_blocker_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		advanced.emit()


## Rulează o interacțiune (o secvență de replici) fără să se suprapună cu alta.
func interact(cb: Callable) -> void:
	if busy or _transitioning:
		return
	busy = true
	hide_tip()
	_hint_btn.visible = false
	await cb.call()
	_hide_portrait()
	busy = false
	_hint_btn.visible = hud_on


func _show_portrait(who: String) -> void:
	var key: String = PORTRAITS.get(who, "")
	if key == "" or not AnimSprite.exists(key + "_vorbit"):
		_portrait_root.visible = false
		return
	if who != _portrait_who:
		if _portrait:
			_portrait.queue_free()
		_portrait = AnimSprite.make(key + "_vorbit")
		var fs := _portrait.frame_size()
		var x: float = 4.0 if who in PORTRAIT_LEFT else W - fs.x - 4.0
		_portrait.position = Vector2(x, H - 70 - fs.y).round()
		_portrait_root.add_child(_portrait)
		_portrait_who = who
	_portrait.playing = true
	_portrait_root.visible = true


func _hide_portrait() -> void:
	_portrait_root.visible = false


func say(who: String, text: String) -> void:
	_show_portrait(who)
	_blocker.visible = true
	_dlg.visible = true
	_dlg_more.visible = false
	_dlg_name.text = who
	_dlg_name.visible = who != ""
	_dlg_text.text = text
	_dlg_text.visible_ratio = 0.0
	_typing = create_tween()
	_typing.tween_property(_dlg_text, "visible_ratio", 1.0, max(0.2, text.length() * 0.025))
	_typing.finished.connect(func():
		_dlg_more.visible = true
		if _portrait:
			_portrait.playing = false)
	await advanced
	if _dlg_text.visible_ratio < 1.0:
		_typing.kill()
		_dlg_text.visible_ratio = 1.0
		if _portrait:
			_portrait.playing = false
		_dlg_more.visible = true
		await advanced
	_dlg.visible = false
	_dlg_more.visible = false
	_blocker.visible = false


func choose(options: Array) -> int:
	for c in _choices.get_children():
		c.queue_free()
	for i in options.size():
		var b := Button.new()
		b.text = options[i]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func(): chosen.emit(i))
		_choices.add_child(b)
	_choices.visible = true
	var i: int = await chosen
	_choices.visible = false
	return i


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func flash(color := Color.WHITE, seconds := 0.6) -> void:
	_fade.color = Color(color.r, color.g, color.b, 1.0)
	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, seconds)
	await t.finished


func shake(strength := 6.0, seconds := 0.5) -> void:
	var t := 0.0
	while t < seconds:
		world.position = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		await get_tree().process_frame
		t += get_process_delta_time()
	world.position = Vector2.ZERO


# ================================================================ scene
func start(first_scene := "title") -> void:
	money = 7
	has_zacusca = false
	flags = {}
	update_hud()
	goto(first_scene)


func goto(scene: String, fade_seconds := 0.45) -> void:
	_transitioning = true
	hide_tip()
	var t := create_tween()
	t.tween_property(_fade, "color", Color(0, 0, 0, 1), fade_seconds)
	await t.finished
	for c in world.get_children():
		c.queue_free()
	var s: Node = load("res://scripts/scenes/%s.gd" % scene).new()
	s.name = scene
	world.add_child(s)
	hud_on = s.get("show_hud") != false
	_hud.visible = hud_on
	_hint_btn.visible = hud_on
	t = create_tween()
	t.tween_property(_fade, "color:a", 0.0, fade_seconds)
	await t.finished
	_transitioning = false
	if s.has_method("enter"):
		interact(Callable(s, "enter"))
