extends Node
## Punctul de intrare: pornește jocul.
## Pentru teste pe previzualizarea web: linkul cu #road (sau alt nume de scenă) sare direct la scena aceea.

func _ready() -> void:
	var h := ""
	if OS.has_feature("web"):
		h = str(JavaScriptBridge.eval("location.hash")).trim_prefix("#")
	if h != "" and ResourceLoader.exists("res://scripts/scenes/%s.gd" % h):
		Game.start(h)
	else:
		Game.start()
