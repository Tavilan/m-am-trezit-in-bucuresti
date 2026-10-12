extends GameScene
## TEST TEMPORAR: animația „decupată” a lui Romică (o singură imagine, tăiată în părți și mișcată din cod).

const RIG := preload("res://scripts/rig.gd")
var _rig: Node2D
var _label := "Respiră"


func _ready() -> void:
	show_hud = false
	bg_color = Color("#2a2a33")
	_rig = RIG.new()
	_rig.position = Vector2(230, 336)
	add_child(_rig)
	var box := VBoxContainer.new()
	box.position = Vector2(430, 70)
	box.add_theme_constant_override("separation", 8)
	box.theme = Game._theme()
	add_child(box)
	for it in [["Respiră și clipește", "idle"], ["Vorbește", "talk"], ["Salută", "wave"], ["Beat criță", "drunk"]]:
		var b := Button.new()
		b.text = it[0]
		b.custom_minimum_size = Vector2(180, 34)
		b.pressed.connect(_set_mode.bind(it[1], it[0]))
		box.add_child(b)
	var back := Button.new()
	back.text = "Înapoi la titlu"
	back.custom_minimum_size = Vector2(180, 34)
	back.pressed.connect(func(): Game.goto("title"))
	box.add_child(back)


func _set_mode(m: String, label: String) -> void:
	_rig.mode = m
	_label = label
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, Game.W, Game.H), bg_color)
	draw_rect(Rect2(0, 330, Game.W, 30), Color("#33333d"))
	draw_string(Game.font, Vector2(16, 26), "Test animație decupată: " + _label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.8))
