extends GameScene
## 3. Birtul Unirea. Fost magazin de la CAP: conserve expirate, tejghea de formică, manele la televizor.
## Firul scenei (nu se poate sări):
##   1. Costel nu-i mai dă pe caiet. Ca să capete o bere, Romică trebuie să facă televizorul să prindă
##      (minijocul cu antena de cameră).
##   2. Cu berea în mână, Marius îl ia peste picior („meșter de sârmă”). Romică se duce la baie să se răcorească.
##   3. Oglinda. La întoarcere, Tanti Mioara îi dă zacusca pentru Gina.
##   4. Runda a doua cu Marius: demonstrația la frigiderul de bere (minijocul cu firele) și focul.
## Gemenii, rafturile, televizorul, fereastra etc. au replici în plus pentru curioși.

const ART := "res://art/final/birt_fundal.png"
const ART_OLD := "res://art/final/birt_fundal_v1.png"   # până vine varianta 2 (fără masa înaltă)
const LAYOUT := "res://art/final/birt_layout.json"
var _fire := false
var _art := false
var _fire_art := false


func _ready() -> void:
	title = "Birtul Unirea"
	music = "res://audio/manele_tv.ogg"   # la televizorul de pe perete, cu difuzor prost
	radio = true
	_fire = Game.flags.get("fire", false)
	if not Game.flags.get("antenna_done", false):
		ambience = "res://audio/tv_purici.ogg"   # televizorul nu prinde: purici, manelele abia se aud
		ambience_db = -10.0
	_art = ResourceLoader.exists(ART) or ResourceLoader.exists(ART_OLD)
	_fire_art = _fire and ResourceLoader.exists("res://art/final/birt_foc.png")
	if _art:
		_build_art()
	else:
		_build_sketch()


## Până vine arta: schiță cu dreptunghiuri, aceleași zone.
func _build_sketch() -> void:
	bg_color = Color("#241c14")
	sketch = [
		[Rect2(0, 260, 640, 100), Color("#33281c"), ""],
		[Rect2(20, 40, 170, 120), Color("#4a3c2a"), "rafturi"],
		[Rect2(20, 170, 200, 70), Color("#7a6a5a"), "tejgheaua"],
		[Rect2(90, 110, 50, 60), Color("#6a4a3a"), "Costel"],
		[Rect2(230, 40, 90, 64), Color("#22303a"), "televizorul"],
		[Rect2(240, 110, 70, 100), Color("#9aa8b0"), "frigiderul de bere"],
		[Rect2(320, 160, 130, 100), Color("#4a5a3a"), "Nelu și Gelu"],
		[Rect2(470, 130, 70, 130), Color("#3a4a6a"), "Marius"],
		[Rect2(160, 170, 40, 80), Color("#6a4a5a"), "Tanti Mioara"],
		[Rect2(570, 40, 60, 210), Color("#3a3028"), "ușa de la baie"],
	]
	_hotspots({
		"costel": Rect2(20, 110, 130, 60), "shelves": Rect2(20, 40, 170, 68), "tv": Rect2(230, 40, 90, 64),
		"fridge": Rect2(240, 110, 70, 100), "twins": Rect2(320, 160, 130, 100), "marius": Rect2(470, 130, 70, 130),
		"mioara": Rect2(160, 170, 40, 80), "bathroom": Rect2(570, 40, 60, 210),
	})


## Cu arta: fundal + personaje așezate după perspectivă. Pozițiile se reglează după desen.
func _build_art() -> void:
	var fire_bg := "res://art/anim/birt_foc/bg.png" if ResourceLoader.exists("res://art/anim/birt_foc/bg.png") else "res://art/final/birt_foc.png"
	background(fire_bg if _fire_art else (ART if ResourceLoader.exists(ART) else ART_OLD))
	horizon = 125   # ochii lui Romică (1,55 m): ușa de 2 m și frigiderul se potrivesc
	lighting = {"ambient": Vector3(0.72, 0.74, 0.7), "saturation": 0.9,
		"light1_pos": Vector2(320, 0), "light1_color": Vector3(0.85, 0.95, 0.9), "light1_radius": 360.0, "light1_strength": 0.45,
		"light2_pos": Vector2(90, 60), "light2_color": Vector3(1.0, 0.8, 0.5), "light2_radius": 200.0, "light2_strength": 0.35}
	grade = {"tint": Vector3(0.88, 0.92, 0.86), "saturation": 0.78}
	if _fire_art:   # birtul arde: totul luminat portocaliu de foc, din dreapta
		lighting = {"ambient": Vector3(0.95, 0.62, 0.4), "saturation": 0.9,
			"light1_pos": Vector2(500, 140), "light1_color": Vector3(1.0, 0.6, 0.25), "light1_radius": 420.0, "light1_strength": 0.7,
			"light2_pos": Vector2(90, 60), "light2_color": Vector3(1.0, 0.8, 0.5), "light2_radius": 200.0, "light2_strength": 0.2}
		grade = {"tint": Vector3(1.0, 0.78, 0.6), "saturation": 0.85}
	if _fire_art and AnimSprite.exists("birt_foc"):   # focul animat (Veo), doar zona care se mișcă, peste fundal
		var fa := AnimSprite.make("birt_foc")
		var aj: Dictionary = JSON.parse_string(FileAccess.open("res://art/anim/birt_foc/anim.json", FileAccess.READ).get_as_text())
		var rg = aj.get("region")
		fa.position = Vector2(rg[0], rg[1]) if rg is Array else Vector2.ZERO
		add_child(fa)
	var L: Dictionary = {}
	if FileAccess.file_exists(LAYOUT):
		L = JSON.parse_string(FileAccess.open(LAYOUT, FileAccess.READ).get_as_text())
	# de la spate în față: Marius (în picioare, în spatele mesei), gemenii la table, Mioara la tejghea
	for who in [["costel", "Costel"], ["marius", "Marius"], ["gemeni", "Nelu"], ["mioara", "Tanti Mioara"]]:
		var path := "res://art/final/%s_birt.png" % who[0]
		if _fire and who[0] != "costel":   # în foc au sărit toți în picioare, spre ușă; rămâne doar Costel la tejghea
			continue
		if ResourceLoader.exists(path) and L.has(who[0]):
			var s := layer(path, Vector2(L[who[0]][0], L[who[0]][1]))
			if who[0] != "gemeni":
				figure(s, who[1])
	var R: Dictionary = L.get("hotspots", {})
	if R.is_empty():
		return
	var rects := {}
	for k in R:
		rects[k] = Rect2(R[k][0], R[k][1], R[k][2], R[k][3])
	_hotspots(rects)


## Întâi lucrurile din fundal, apoi oamenii (ultimele adăugate sunt deasupra și prind atingerea).
func _hotspots(r: Dictionary) -> void:
	hotspot("Rafturile", r["shelves"], _shelves)
	if r.has("window"):
		hotspot("Geamul", r["window"], _window)
	if r.has("stove"):
		hotspot("Soba", r["stove"], _stove)
	hotspot("Televizorul", r["tv"], _tv)
	hotspot("Frigiderul de bere", r["fridge"], _fridge)
	hotspot("Ușa de la baie", r["bathroom"], _bathroom)
	hotspot("Costel, birtașul", r["costel"], _costel)
	hotspot("Marius, nepotul", r["marius"], _marius)
	hotspot("Nelu și Gelu", r["twins"], _twins)
	hotspot("Tanti Mioara", r["mioara"], _mioara)


func enter() -> void:
	if _fire:
		await _after_fire()
	elif Game.flags.get("mirror_done", false) and not Game.has_zacusca:
		await say("Tanti Mioara", "Romică! Stai, maică, că era să uit.")
		await _give_zacusca()
	elif not Game.flags.get("pub_seen", false):
		Game.flags["pub_seen"] = true
		await say("Nelu", "Costele, iar ninge la televizor!")
		await say("Gelu", "Ninge!")
		await say("Costel", "Ninge, că plouă. Ce vreți să fac, să mă urc pe casă?")
		await say("Costel", "...Romică. Ce cauți la ora asta?")
		await say("Romică", "Ce să caut, Costele. O bere.")


func _process(_d: float) -> void:
	if _fire:
		queue_redraw()


func _draw() -> void:
	super._draw()
	if _fire and not _fire_art:
		# fără arta cu focul: doar lumina portocalie care pâlpâie (fără flăcări desenate din cod)
		draw_rect(Rect2(0, 0, Game.W, Game.H), Color(1, 0.45, 0.12, 0.22 + 0.06 * sin(Time.get_ticks_msec() * 0.02) + randf() * 0.03))


# ---------------------------------------------------------------- Costel și berea

func _costel() -> void:
	if _fire:
		await say("Costel", "Nu-mi mai vorbi, Romică! Nu-mi mai vorbi!")
		return
	if Game.flags.get("beer", false):
		await cycle("costel_after", [
			[["Costel", "Bea-o încet, că alta nu-ți mai dau."]],
			[["Romică", "Costele, și-un mic?"], ["Costel", "Micii s-au terminat în '98, odată cu CAP-u'."]],
			[["Costel", "Ce te uiți așa? Nu-ți mai dau pe caiet. Caietu' s-a terminat."]],
		])
		return
	if Game.flags.get("antenna_asked", false):
		await cycle("costel_wait", [
			[["Costel", "Întâi televizoru'. Pe urmă vorbim de bere."]],
			[["Costel", "Antena, Romică. Antena de pe televizor."]],
		])
		return
	await say("Costel", "Bere? Ai bani?")
	var a := await Game.choose(["„Trece-mă pe caiet, Costele.”", "„Am, da' îs de lemne.”"])
	if a == 0:
		await say("Romică", "Trece-mă pe caiet, Costele.")
		await say("Costel", "Pe caiet? Ai două pagini numa' tu. Cu tot cu frigideru' pe care mi l-ai reparat.")
		await say("Romică", "Atunci pune-mă pe copertă.")
	else:
		await say("Romică", "Am, da' îs de lemne. Mi-a zis Gina.")
		await say("Costel", "Atunci du-te și cumpără lemne. Aici e birt.")
	await say("Costel", "Uite ce. Televizoru' ăla nu prinde de-o săptămână și ăștia doi mă scot din minți.")
	await say("Costel", "Fă-l să prindă și-ți dau o bere. Una. Pe gratis.")
	Game.flags["antenna_asked"] = true


func _tv() -> void:
	if _fire:
		await say("Romică", "Televizoru' merge. Singuru' lucru care mai merge aici.")
		return
	if Game.flags.get("antenna_done", false):
		await cycle("tv_after", [
			"Prinde ca la București. Manele în HD. Adică în «HaDe», cum zice Costel.",
			"Antena legată de cui cu sârmă. Dacă bate vântul, iar ninge.",
			"Ăla de cântă e din Craiova. Sau din Băilești. Toți de-acolo-s.",
		])
		return
	if not Game.flags.get("antenna_asked", false):
		await cycle("tv_before", [
			"Televizoru' de la CAP. Prinde trei programe, și două-s același.",
			"Ninge pe el. Afară plouă, la televizor ninge.",
		])
		return
	await say("Romică", "Ia să vedem antena asta...")
	await _antenna_game()
	Game.flags["antenna_done"] = true
	Game.set_audio(music, "", true)
	await say("Nelu", "Prinde! Băăă, prinde!")
	await say("Gelu", "Prinde!")
	await say("Costel", "Ce-i făcuși?")
	await say("Romică", "O legai de cui cu sârmă. Să nu se mai miște.")
	await say("Costel", "Cu sârmă. Normal. Na-ți berea. Bea-o încet, că alta nu-ți mai dau.")
	Game.flags["beer"] = true


func _antenna_game() -> void:
	var g: CanvasLayer = preload("res://scripts/scenes/antenna_game.gd").new()
	Game.world.get_parent().add_child(g)
	await say("Romică", "Antena de cameră. Când o ții în mână, prinde. Când îi dai drumu', iar ninge. Trebe găsit locu' unde prinde singură.")
	await g.finished
	g.queue_free()


# ---------------------------------------------------------------- Marius

func _marius() -> void:
	if _fire:
		await say("Marius", "Unchiule... nu mai zic nimic. Nimic.")
		return
	if not Game.flags.get("beer", false):
		await cycle("marius_early", [
			[["Marius", "Uuu, unchiu'! Guten Abend!"], ["Romică", "Lasă-mă cu gutănabendu'. Întâi iau o bere. Cu neamțu' nu vorbesc treaz."]],
			[["Romică", "Stă la masă cu telefonu' în mână și se uită la toată lumea de sus. Întâi berea."]],
		])
		return
	if not Game.flags.get("marius_jab", false):
		await say("Marius", "Unchiule! Am auzit de mașina de spălat. Toată comuna a auzit.")
		await say("Marius", "Uite, ăsta-i certificatu' meu. Elektriker. Cu ștampilă de la Stuttgart.")
		var a := await Game.choose(["„Și ce scrie pe el, mă?”", "„Eu te-am învățat să ții șurubelnița.”"])
		if a == 0:
			await say("Romică", "Și ce scrie pe el, mă?")
			await say("Marius", "Scrie că am voie să bag mâna-n tablou. Tu n-ai voie să bagi mâna nici în priză.")
		else:
			await say("Romică", "Eu te-am învățat să ții șurubelnița, mă.")
			await say("Marius", "Și de-aia am stat trei ani să mă dezvăț. În Germania asta se cheamă pericol public.")
		await say("Marius", "Ești meșter de sârmă, unchiule. Asta ești. Meșter de sârmă.")
		await say("Nelu", "Hă-hă! Meșter de sârmă!")
		await say("Gelu", "De sârmă!")
		await say("Romică", "...")
		await say("Romică", "Mă duc să mă spăl pe față. Că-mi sare țandăra și nu vreau să fac moarte de om.")
		Game.flags["marius_jab"] = true
		return
	if not Game.flags.get("mirror_done", false):
		await say("Romică", "Nu acu'. Întâi apă rece pe față.")
		return
	if not Game.has_zacusca:
		await say("Romică", "Tanti Mioara îmi face semn de la tejghea. Ce-o mai vrea și ea?")
		return
	await say("Marius", "Ți-a trecut, unchiule? Hai, nu te supăra. Știi ce-i cu frigideru' lu' Costel?")
	await say("Marius", "Nu răcește de-o săptămână. Berea-i caldă ca ceaiu'. L-ai reparat tu, nu?")
	await say("Costel", "El mi l-a reparat. Cu sârmă.")
	await say("Nelu", "Cu sârmă!")
	await say("Romică", "Meșter de sârmă, ziseși?")
	await say("Romică", "Costele, dă-te la o parte. Uitați-vă și-nvățați. Îi arătai io și Germaniei.")
	Game.goto("wires")


# ---------------------------------------------------------------- baia, Mioara

func _bathroom() -> void:
	if _fire:
		await say("Romică", "Nu mă bag acolo. Acolo arde.")
		return
	if Game.flags.get("mirror_done", false):
		await say("Romică", "Mă spălai o dată azi. Ajunge, că nu-i Paști.")
		return
	if not Game.flags.get("marius_jab", false):
		await cycle("bathroom_early", [
			"Baia. N-am treabă acolo. Încă.",
			"Ușa de la baie nu se închide din '91. Se ține cu piciorul.",
		])
		return
	Game.goto("bathroom")


func _mioara() -> void:
	if Game.has_zacusca:
		await cycle("mioara_after", [
			[["Tanti Mioara", "Ai grijă de borcan, Romică. E de la soră-mea din Craiova."]],
			[["Tanti Mioara", "Și să-i zici Ginei că nu eu am zis de mașina de spălat la toată lumea. Că n-am zis eu."]],
			[["Tanti Mioara", "Am zis, da' numa' la două."]],
		])
		return
	if not Game.flags.get("mirror_done", false):
		await cycle("mioara_before", [
			[["Tanti Mioara", "Romică, maică! Am auzit-o pe Gina până la mine. Ce i-ai făcut, mă?"], ["Romică", "I-am reparat mașina."], ["Tanti Mioara", "Doamne ferește. Și pe mine m-ai reparat la televizor, acum doi ani. Nici acum nu-l pot opri."]],
			[["Tanti Mioara", "Am venit după ulei. Și să văd cine mai e pe-aici. Ulei mai am."]],
			[["Tanti Mioara", "Neamțu' ăla-i nepotu-tău, nu? Seamănă cu soră-ta. Mai ales când se laudă."]],
		])
		return
	await _give_zacusca()


func _give_zacusca() -> void:
	await say("Tanti Mioara", "Romică, maică, ia zacusca asta de la mine și du-i-o Ginei. Cu zacuscă se împacă orice ceartă.")
	Game.has_zacusca = true
	Game.update_hud()
	await say("Romică", "Mulțumesc, tanti Mioara. O țin la mine ca pe ochii din cap.")
	await say("Tanti Mioara", "Să nu-l spargi, că-i borcan de-al meu. Vreau borcanu' înapoi.")


# ---------------------------------------------------------------- curioși

func _twins() -> void:
	if _fire:
		await say("Nelu", "Hai, Romică, hai cu noi.")
		return
	if Game.flags.get("marius_jab", false):
		await cycle("twins_late", [
			[["Nelu", "Nu te supăra, Romică. Am râs și noi așa."], ["Gelu", "Așa!"]],
			[["Gelu", "Șase-cinci! Poartă!"], ["Nelu", "Ce poartă, mă? Nu-i poartă. Poarta-i la Ilie."]],
		])
		return
	await cycle("twins", [
		[["Nelu", "Romică! Joci o mână de table?"], ["Gelu", "O mână!"], ["Romică", "Nu joc cu voi. Voi aruncați zarurile de două ori, că sunteți doi."]],
		[["Nelu", "Costel nu mai dă pe caiet de când i-ai reparat frigideru'."], ["Gelu", "De-atunci!"]],
		[["Nelu", "Marius zice că-n Germania birturile au wifi."], ["Gelu", "Uaifai!"], ["Romică", "Și la ce le trebe? Să vorbească cu berea?"]],
		[["Gelu", "Dubla!"], ["Nelu", "Nu-i dubla, mă, că ți-a sărit zaru' sub masă."]],
	])


func _shelves() -> void:
	await cycle("shelves", [
		"Conserve de pește din '98. Peștele e mai bătrân ca nepotu-meu.",
		"Biscuiții ăștia au fost pe raft când a căzut Ceaușescu. Și n-au căzut ei.",
		"Sticlele fără etichetă-s de la Costel de-acasă. Țuică de prună. Sau de orice-a căzut în butoi.",
	])


func _fridge() -> void:
	if Game.flags.get("marius_jab", false):
		await say("Romică", "Frigideru' de bere. Am io o idee. Da' întâi să-l aud pe neamț ce mai zice.")
		return
	await cycle("fridge", [
		[["Costel", "Nu mai răcește de-o săptămână. Berea-i caldă ca ceaiu'."]],
		[["Romică", "Are sârma mea pe compresor. Sârma e bună. Compresoru' e de vină."]],
	])


func _window() -> void:
	await cycle("window", [
		"Plouă de rupe. Acasă Gina se uită la serial și zice că nu mă așteaptă.",
		"Pe geam se vede felinaru' meu. Clipește. Deci merge.",
	])


func _stove() -> void:
	await cycle("stove", [
		"Soba de tablă. Costel face focu' numa' când vine popa.",
		"Burlanu' l-am legat io cu sârmă. Ține de zece ani. Să mai zică neamțu' ceva.",
	])


func _after_fire() -> void:
	await Game.shake(5.0, 0.6)
	await say("Costel", "Ardeee! Mi-ai dat foc la birt, Romică!")
	await say("Romică", "La jumătate! Jumătate-i întreagă!")
	await say("Costel", "Ieși afară! Ieși afară până nu te-omor!")
	await say("Marius", "Gata, unchiule. Hai afară, să te răcorești.")
	await say("Nelu", "Hai, Romică, hai cu noi.")
	await say("Gelu", "Hai cu noi!")
	Game.goto("station")
