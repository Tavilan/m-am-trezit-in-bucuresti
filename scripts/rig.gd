extends Node2D
## Personaj animat „decupat”: o singură imagine tăiată în părți (tools/art/rig_cut.py),
## mișcată din cod: respirație, clipit, vorbit, gesturi, clătinat.
## Poziția nodului = punctul dintre tălpi.

var rig_dir := "res://art/rigs/romica"
var mode := "idle"          # idle | talk | wave | drunk

var _t := 0.0
var _blink_in := 2.5
var _blink_left := 0.0
var _wave := 0.0            # 0 = braț jos, 1 = ridicat
var _lurch := 0.0
var _hip: Node2D
var _neck: Node2D
var _jaw: Node2D
var _elbow_l: Node2D
var _elbow_r: Node2D
var _head: Sprite2D
var _tex_head: Texture2D
var _tex_blink: Texture2D
var _neck_base := Vector2.ZERO
var _jaw_base := Vector2.ZERO


func _ready() -> void:
	var rig: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(rig_dir + "/rig.json"))
	var pv: Dictionary = rig["pivots"]
	var feet := _v(pv["feet"])
	_hip = Node2D.new()
	add_child(_hip)
	_sprite(_hip, rig, "body", feet)
	_elbow_l = _joint(_hip, _v(pv["elbow_l"]) - feet)
	_sprite(_elbow_l, rig, "forearm_l", _v(pv["elbow_l"]))
	_elbow_r = _joint(_hip, _v(pv["elbow_r"]) - feet)
	_sprite(_elbow_r, rig, "forearm_r", _v(pv["elbow_r"]))
	_neck = _joint(_hip, _v(pv["neck"]) - feet)
	_neck_base = _neck.position
	_head = _sprite(_neck, rig, "head", _v(pv["neck"]))
	_tex_head = _head.texture
	_tex_blink = load(rig_dir + "/head_blink.png")
	_jaw = _joint(_neck, _v(pv["jaw"]) - _v(pv["neck"]))
	_jaw_base = _jaw.position
	_sprite(_jaw, rig, "jaw", _v(pv["jaw"]))


func _v(a: Array) -> Vector2:
	return Vector2(a[0], a[1])


func _joint(parent: Node2D, pos: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	parent.add_child(n)
	return n


func _sprite(parent: Node2D, rig: Dictionary, part: String, pivot: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(rig_dir + "/" + part + ".png")
	s.centered = false
	s.position = _v(rig["parts"][part]["origin"]) - pivot
	parent.add_child(s)
	return s


func _process(d: float) -> void:
	_t += d
	var drunk := mode == "drunk"
	# clătinat din tălpi (mult mai tare când e beat, cu câte o „smucitură”)
	if drunk and randf() < d * 0.5:
		_lurch = randf_range(-1.0, 1.0)
	_lurch = move_toward(_lurch, 0.0, d * 0.6)
	var sway := (3.5 if drunk else 0.7) * sin(_t * (0.9 if drunk else 0.7)) + _lurch * 6.0
	_hip.rotation = deg_to_rad(sway)
	# respirație: capul urcă un pixel în ritmul respirației
	var breath := 1.0 if sin(_t * 1.8) > 0.55 else 0.0
	_neck.position = _neck_base + Vector2(0, -breath)
	var nod := 0.0
	if mode == "talk":
		nod = 2.0 * sin(_t * 5.0)
	_neck.rotation = deg_to_rad(1.2 * sin(_t * 1.1) + nod - sway * 0.4)
	# vorbit: falca coboară 0-2 pixeli, neregulat
	if mode == "talk":
		var k := int(_t * 11.0)
		_jaw.position = _jaw_base + Vector2(0, [0, 1, 2, 1, 0, 2, 1, 0][k % 8])
	else:
		_jaw.position = _jaw_base
	# clipit
	_blink_in -= d
	if _blink_in <= 0.0:
		_blink_left = 0.12
		_blink_in = randf_range(2.5, 5.0) * (0.5 if drunk else 1.0)
	_blink_left -= d
	_head.texture = _tex_blink if _blink_left > 0.0 else _tex_head
	# brațe: atârnă cu clătinatul; „salută” ridică antebrațul drept și face cu mâna
	_wave = move_toward(_wave, 1.0 if mode == "wave" else 0.0, d * 3.0)
	_elbow_l.rotation = deg_to_rad(-sway * 0.8 + 2.0 * sin(_t * 1.3))
	var lift := -125.0 * _ease(_wave)
	var flap := 18.0 * sin(_t * 9.0) * _ease(_wave)
	_elbow_r.rotation = deg_to_rad(-sway * 0.8 + lift + flap)


func _ease(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)
