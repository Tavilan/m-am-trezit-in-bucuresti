class_name AnimSprite
extends Sprite2D
## Animație din art/anim/<nume>/ (sheet.png + anim.json, făcute de tools/art/video_to_sprite.py).
## `playing = false` îngheață pe cadrul 0 (poza de bază).

var fps := 12.0
var frames := 1
var cols := 1
var playing := true
var _t := 0.0


static func exists(anim_name: String) -> bool:
	return ResourceLoader.exists("res://art/anim/%s/sheet.png" % anim_name)


static func make(anim_name: String) -> AnimSprite:
	var s := AnimSprite.new()
	s.load_anim(anim_name)
	return s


func load_anim(anim_name: String) -> void:
	var dir := "res://art/anim/%s/" % anim_name
	texture = load(dir + "sheet.png")
	var f := FileAccess.open(dir + "anim.json", FileAccess.READ)
	if f:
		var j: Dictionary = JSON.parse_string(f.get_as_text())
		frames = int(j.get("frames", 1))
		fps = float(j.get("fps", 12))
		cols = int(j.get("cols", frames))
	hframes = max(1, cols)
	vframes = max(1, int(ceil(frames / float(hframes))))
	centered = false
	frame = 0


## Dimensiunea unui cadru, în pixeli.
func frame_size() -> Vector2:
	return Vector2(texture.get_width() / float(hframes), texture.get_height() / float(vframes))


func _process(d: float) -> void:
	if not playing:
		if frame != 0:
			frame = 0
		_t = 0.0
		return
	_t += d
	frame = int(_t * fps) % frames
