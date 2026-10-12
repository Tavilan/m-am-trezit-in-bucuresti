# Cum se face arta

## Metoda folosită acum: manual, fără niciun cost (decizia lui Tavi, 12.10.2026)
1. Claude scrie promptul (fișierul `art/prompts/<id>.json` + ghidul de stil `_style.md`) și i-l dă lui Tavi gata de copiat.
2. Tavi îl lipește în aplicația **ChatGPT** și/sau **Gemini** (incluse în abonamentele lui) și trimite imaginea în chat.
3. Claude o importă: `python3 tools/art/import_image.py <id> <imagine> <chatgpt|gemini|poza-proprie> [--variant ...]`. Imaginea ajunge în `art/raw/`, varianta pixelizată în `art/final/`, iar sursa se notează în `art/LOG.md`.
4. Personajele se cer pe **fundal verde plin (#00FF00)**, scos automat la import (`manual_key` în prompt).

## Fotografii reale
- **Se pot transforma în artă** doar fotografiile pe care avem dreptul să le modificăm comercial:
  - **pozele făcute de Tavi** (cea mai bună sursă: realism maxim, drepturi complete);
  - imagini în domeniul public / CC0 sau cu licențe ca Unsplash ori Pexels, cu sursa notată în `art/LOG.md`.
- Pozele din presă sau de pe site-uri oarecare sunt protejate: se folosesc **doar ca sursă de fapte** (scrise în prompt), niciodată ca imagine de transformat sau de dat ca referință.

## Varianta automată prin API (pregătită, dar oprită: cere card)

1. **Promptul:** fiecare imagine are un fișier `art/prompts/<id>.json` (tip, mărime, calitate, referințe, text). La fiecare prompt se adaugă în față ghidul de stil comun, `art/prompts/_style.md`: realism, lizibilitate, lumină, satira corectă și **fără text în imagine** (textul îl pune jocul).
2. **Generarea:** la orice modificare în `art/prompts/`, workflow-ul „Generează artă” cheamă API-ul de imagini OpenAI (`tools/art/generate.py`). Se poate porni și manual: tab-ul **Actions** → „Generează artă” → **Run workflow**, cu ID-urile dorite.
3. **Pixelizarea:** `tools/art/pixelize.py` aduce imaginea pe grila fixă (scene 640×360; personaje la înălțimea cerută, cu margini curate), cu paletă nelimitată.
4. **Rezultatul** se salvează singur în repository: `art/raw/<id>.png` (brut), `art/final/<id>.png` (pixel-art), `art/LOG.md` (costul estimat al fiecărei imagini). Apoi previzualizarea web se reface singură.
5. **Verificarea:** un singur test orb pe scena terminată.

## Reguli
- Cheia API stă **doar** în secretul `OPENAI_API_KEY` al repository-ului. Nu se scrie niciodată în fișiere sau în chat.
- **Referințe** (`refs`): doar imagini proprii, și **doar ale aceluiași personaj** (foaia lui de personaj, când îi facem portretul sau o scenă cu el). Niciodată foaia altui personaj ca „referință de stil”: modelul îi copiază fața (vezi mai jos). Fotografiile reale de pe internet se folosesc doar ca sursă de fapte în prompt, nu ca imagini de intrare.
- Plafon: maximum 4 imagini pe rulare, ca să nu apară facturi surpriză.
- Arta pe straturi: fundaluri **fără personaje**, iar personajele și obiectele interactive ca imagini separate, cu fundal transparent.

## Test ChatGPT vs Gemini (12.10.2026, Romică: foaia de personaj + oglinda)
Test orb pe variantele pixelizate (realism / lizibilitate / impresie):
- **ChatGPT:** foaie 8/6/7, oglindă 8/7/8. Câștigă la realism și atmosferă: proporții reale, oglinda arată camera reflectată. Minusuri: fața din oglindă pare că plânge (strică gluma), colacul de sârmă se citește ca un cârnat, textura e zgomotoasă.
- **Gemini:** foaie 6/9/7, oglindă 6/8/6. Câștigă la lizibilitate (contur curat, clar ca sprite). Minusuri: proporții de desen animat (cap mare); oglinda arată ca un portret înrămat, nu ca o reflexie.
- **Decizie:** ChatGPT, pentru că realismul primează. Corecturile (privire seacă fără lacrimi, sârmă subțire, rola de bandă mai mare, mai puțin zgomot) sunt trecute în prompturi (versiunea 4).

## Animații: regula de calitate (12.10.2026)
- **Mai bine fără animație decât cu una care arată ieftin.** Testul cu animație „decupată” (o imagine tăiată în părți și rotită din cod) a fost respins de Tavi: arată ca o glumă. Scos din joc.
- **Metoda aprobată (12.10.2026): video → pixel-art.** Tavi generează în Gemini (Veo, inclus în abonament) un video scurt pornind de la imaginea exactă a personajului, pe fundal verde, cu cameră fixă. `tools/art/video_to_sprite.py` îl transformă: scoate verdele, ancorează tălpile, pixelizează toate cadrele pe aceeași grilă, stabilizează tremuratul față de cadrul median și alege bucla care se leagă cel mai bine. Ieșire în `art/anim/<nume>/` (cadre, sheet, anim.json, preview.gif). Prima animație: `romica_idle_beat` (60 de cadre, 12 fps), acceptată de Tavi.
- Rezervă: fără mișcare, doar schimbări de expresie (portrete generate cu referință) și efecte de ambianță din cod.

## Decizii globale fixate (12.10.2026)
- **Personaje:** stau în scenă la mărime reală; la dialog apare și un **portret mare**, detaliat, cu expresie și animație. Deci fiecare personaj important are: foaie de personaj (întreg, fundal verde) + portret de dialog.
- **Cameră:** **un cadru fix 16:9 pe fiecare loc**, ca un tablou. Fără panorame și fără mai multe unghiuri pe același loc.
- **Stil global:** lumină realistă proprie fiecărei scene, apoi **aceeași gradare de culoare** pentru tot jocul (aplicată din cod la pixelizare), ca să pară unitar.
- **Animații Veo:** personajele principale au două bucle, **așteptare** și **vorbit**; cele secundare doar **așteptare**.

## Personaje distincte (12.10.2026)
- **Problema:** prima serie de personaje secundare semăna prea mult cu Romică (aceeași mustață, nas roșu, sprâncene, aceeași înălțime). Cauze: foaia lui Romică dată ca referință tuturor, fețe nedescrise în prompt și toate personajele aduse la 300 px.
- **Regula:** fiecare prompt de personaj descrie explicit **CORPUL** (înălțime, constituție, postură) și **FAȚA** (formă, nas, ochi, păr, barbă/mustață sau lipsa lor). Doar băutorii au nas roșu. Siluetele trebuie să se deosebească și în umbră.
- **Înălțimi reale:** câmpul `height_cm` din `art/prompts/<id>.json`; toate foile de personaj au aceeași scară, **195 cm = 300 px** (`CHAR_PX_PER_CM` în `pixelize.py`). Romică 165, Gina 168, Marius 182, Nelu și Gelu 195, Costel 182, Tanti Mioara 150, turistul 190.
- **Verificare:** `tools/art/lineup.py` pune personajele unul lângă altul, la scara reală.

## Animații Veo automate (12.10.2026)
- Claude face singur pașii din Gemini (prin Claude in Chrome, pe Mac-ul lui Tavi): încarcă imaginea, scrie promptul, așteaptă, descarcă video-ul în Downloads, apoi îl convertește cu `video_to_sprite.py`. Cost zero (inclus în abonamentul Gemini Pro).
- Imaginea de pornire trebuie să fie **16:9**, cu loc deasupra capului: Veo face video 16:9 și taie ce nu încape (la primul test, cu o imagine 4:3, i-a tăiat șapca lui Romică).
- Imaginile de încărcat trebuie să fie în folderul de lucru al sesiunii (căile de pe Mac nu sunt acceptate de încărcarea din Chrome).

## Personajele în scenă: lumină și perspectivă (12.10.2026)
- **Lumina scenei** (`shaders/scene_light.gdshader`): fiecare scenă își descrie lumina în `lighting` (culoare ambientală, două surse punctuale, saturație). Personajele și obiectele primesc automat lumina locului: mai calde și mai slabe seara în bucătărie, albăstrui noaptea pe drum, mai luminate lângă bec/felinar. Calculul e pe fiecare pixel al grilei 640×360, deci pixelii rămân curați.
- **Perspectivă:** fiecare fundal are `horizon` (linia ochilor lui Romică, 1,55 m). Un personaj cu tălpile la y are înălțimea `(y − horizon) × cm / 155` pixeli (`height_px()` în `game_scene.gd`). Varianta pentru scenă se face din imaginea brută, la mărimea exactă: `tools/art/scene_sprite.py <id> <px> <nume>` (nu scalăm în joc).
- **Un singur loc o dată:** cât timp portretul cuiva e în prim-plan la dialog, figura lui din scenă dispare (`figure()` în scenă).
- **Romică** nu are portret la dialog (persoana întâi), doar în oglindă și ~5 momente-cheie (`Game.hero_portrait`).
- **Text:** fontul Jersey 15 (OFL), mărimea 20; la derulare, un sunet scurt, cu „voce” diferită pentru fiecare personaj (`audio/text_blip.wav`, înălțimi în `Game.VOICE`).
- **Lumini care se aprind și se sting** (felinare, becuri): nu se desenează cu forme peste imagine. Din același fundal se face varianta „stinsă” cu `tools/art/light_off.py` (scoate lumina caldă a becului de pe stâlp, pereți, gard și băltoace, plus aura din cer; becul devine sticlă stinsă), iar jocul le combină aditiv: imaginea = stinsă + (aprinsă − stinsă) × intensitate, cu lumina mai roșiatică la intensitate mică (`shaders/light_mix.gdshader`). Pâlpâitul felinarului de pe drum (două variante: stingere completă, apoi căderi la 30–60%) a fost respins de Tavi ca nerealist; e oprit, felinarul arde constant. Codul rămâne pentru o încercare viitoare (ex. pâlpâit filmat cu Veo pe tot fundalul).
- **Ploaia** din aer: trei straturi de adâncime (departe mici și lenți, aproape lungi și rapizi), înclinați de vânt; stropii se văd mai ales unde sunt luminați din spate (felinar, vitrină) și capătă culoarea luminii; cei din față se sparg pe drum în mici coroane, iar în băltoace apar cercuri.
