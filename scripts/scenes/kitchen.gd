extends GameScene
## 1. Bucătăria lui Romică, seara. Cearta cu Gina; mașina de spălat „reparată” se plimbă prin bucătărie.

var _washer: Node2D


func _ready() -> void:
	title = "Acasă la Romică, seara"
	bg_color = Color("#2a2018")
	sketch = [
		[Rect2(0, 250, 640, 110), Color("#3b2c20"), ""],
		[Rect2(20, 60, 120, 190), Color("#4a3a2a"), "ușa"],
		[Rect2(470, 50, 60, 70), Color("#6a5228"), "icoana"],
		[Rect2(250, 90, 90, 180), Color("#7a4a5a"), "Gina"],
		[Rect2(380, 160, 220, 90), Color("#5a4632"), "masa, aragazul"],
	]
	_washer = preload("res://scripts/scenes/washer.gd").new()
	_washer.position = Vector2(150, 200)
	add_child(_washer)
	hotspot("Gina", Rect2(250, 90, 90, 180), _gina)
	hotspot("Mașina de spălat", Rect2(150, 200, 80, 80), _washer_talk)
	hotspot("Icoana", Rect2(470, 50, 60, 70), _icon)
	hotspot("Ușa", Rect2(20, 60, 120, 190), _door)


func enter() -> void:
	await say("Gina", "Romicăăă! Ce-ai făcut, mă, la mașina de spălat?!")
	await say("Romică", "O reparai. Merge, nu?")
	await say("Gina", "Merge! Merge prin toată bucătăria! Uite-o că vine spre mine!")


func _gina() -> void:
	if Game.flags.get("gina_done", false):
		await say("Gina", "Ce mai stai? Du-te!")
		return
	await say("Romică", "Gino, fă, ascultă-mă...")
	var i := await Game.choose(["„Las' că o mai leg o dată, mai strâns.”", "„Mă duc până la birt, să mă gândesc la o soluție.”"])
	if i == 0:
		await say("Romică", "Las' că o mai leg o dată. Mai strâns. Cu sârmă de-aia groasă.")
		await say("Gina", "Să nu te mai prind cu sârma ta în casa mea!")
	else:
		await say("Romică", "Mă duc până la birt. Acolo îmi vin ideile.")
		await say("Gina", "Ideile tale ne-au lăsat fără mașină de spălat!")
	await say("Gina", "Du-te, du-te! Și să nu te mai întorci până nu te trezești!")
	Game.flags["gina_done"] = true


func _washer_talk() -> void:
	await say("Romică", "Sârmă de doi milimetri, legată ca la carte. Problema e la centrifugă, nu la mine.")


func _icon() -> void:
	await say("Romică", "Doamne, ajută-mă să nu mai repar nimic azi.")


func _door() -> void:
	if not Game.flags.get("gina_done", false):
		await say("Romică", "Întâi să-i zic ceva Ginei. Să nu zică că plecai ca un hoț.")
		return
	await say("Romică", "Plecai.")
	Game.goto("road")
