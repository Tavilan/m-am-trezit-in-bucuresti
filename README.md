# M-am trezit în București
**I Woke Up in Bucharest.** Joc la persoana întâi, pixel-art, în Godot 4: explorare point-and-click + minigame-uri arcade și puzzle-uri. Română + engleză. Țintă: Steam (PC/Mac).

## Premisa
Un bețiv simpatic de la țară se îmbată la cârciumă și se trezește (din somn și din beție) cu trenul în Gara de Nord.
Câștigi când faci rost de bani pentru biletul de întoarcere. Orașul te trimite mereu un pas înainte și doi înapoi.

## Structura jocului
- **Explorare point-and-click** la persoana întâi: scene detaliate, personaje care vin în fața jucătorului, elemente amuzante ascunse pe care dai click/tap.
- **Minigame-uri arcade și puzzle-uri** integrate în poveste (de exemplu modalitățile eroului de a face rost de bani), cu control propriu fiecare.
- **Dialoguri cu ramificații** și scenarii care duc la **2–3 finaluri**.
- Durată: **cel puțin 2–3 ore**.

## Reguli de proiect (obligatorii pentru oricine lucrează aici, om sau AI)

### 1. Calitatea: Steam e ținta, web-ul e doar previzualizare
- Arta, animațiile și efectele se fac la **calitatea finală pentru Steam**, fără compromisuri pentru web.
- Exportul web (GitHub Pages) există **doar ca să fie testat jocul de pe telefon**. Dacă ceva e prea greu pe telefon, se adaptează doar previzualizarea (încărcare scenă cu scenă, setare „calitate redusă” activă doar pe web). Fișierele originale rămân neatinse.
- **Orice reducere de calitate o aprobă Tavi explicit.** Nu se face din reflex; dacă se propune, se explică de ce.

### 2. Satira
Lovește orașul, șmecheriile, comportamentele și instituțiile (taximetristul cu „ORIUNDE 150 LEI”, birocrația, cârpelile). **Nu** lovește eroul și nici grupuri de oameni (etnii, săraci, oamenii străzii). Eroul e simpatic; publicul e de partea lui.

### 3. Arta: pipeline hibrid
1. Referințe foto reale ale locului + fișa de realism (`facts.json`: element, culoare, poziție, sursă, status `verificat` / `aproximat` / `satiră`).
2. Ilustrația de bază e generată de un generator de imagini AI după fișă (eticheta AI de pe Steam se declară deschis).
3. Codul o aduce la **pixel-art adevărat pe grilă fixă 640×360**, cu pixeli uniformi și paleta comună a jocului.
4. Lumina, ploaia și animațiile se pun din cod, peste.
5. **Testul orb:** cineva care vede doar imaginea spune ce recunoaște. Orice glumă care nu e recunoscută se repară sau se scoate.
6. Glumele bune sunt situații vizuale mari, în prim-plan, nu etichete mici.

### 4. Tehnic
- Rezoluție internă 640×360, scalare doar cu numere întregi, filtrare nearest (pixeli curați).
- Renderer: Compatibility (merge identic pe desktop și pe web pentru 2D).
- Interacțiunea e prin click/tap, deci trebuie să meargă la fel cu mouse și cu degetul. Tap-ul e convertit automat în click (`emulate_mouse_from_touch`), deci în cod se tratează **doar** `InputEventMouseButton`; dacă se tratează și `InputEventScreenTouch`, fiecare tap se numără de două ori (verificat în testul tehnic din 11.10.2026).
- Jocul e orizontal (16:9): pe telefon se ține în landscape.
- **Minigame-urile** se proiectează pentru controlul de pe PC (mouse/tastatură; ținta e Steam). Pentru previzualizarea de pe telefon primesc controale tactile echivalente (atingere, tragere, butoane pe ecran), ca să poată fi testate, fără să se simplifice jocul de pe PC.

## Structura
- `scenes/`: scenele Godot (.tscn)
- `scripts/`: GDScript
- `art/`: arta finală a jocului (doar ce a trecut prin pipeline)
- `audio/`: muzică și sunete
- `locale/`: traduceri RO/EN
- `docs/`: povestea, fișele de realism, deciziile

## Previzualizare pe telefon
La fiecare push pe `main`, GitHub Actions exportă jocul pe web și îl publică pe GitHub Pages
(`https://tavilan.github.io/m-am-trezit-in-bucuresti/`). Cât timp nu există nicio scenă, pagina arată doar un mesaj de așteptare.
