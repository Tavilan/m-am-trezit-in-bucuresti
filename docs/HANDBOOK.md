# Handbook: lecții din corecturile lui Tavi

Reguli scurte, adunate din toate corecturile de până acum (oct. 2026). Le citește oricine lucrează la joc (Claude, ChatGPT/Codex) **înainte** să facă ceva nou și le verifică **înainte** să-i arate lui Tavi. Fiecare regulă are în paranteză greșeala din care a venit.

## 0. Cum lucrăm
1. **Verifică singur înainte să arăți.** Build web local, captură în Playwright (ecran de telefon), privește imaginea. Pentru orice mișcare (animație, lumină, ploaie): filmează 10–20 s și uită-te la cadre. Nu-i trimite lui Tavi ceva ce n-ai văzut.
2. **Arată-i rezultatul, nu procesul.** Pe scurt, în română, ce s-a schimbat și ce poate testa la linkul de previzualizare (`#nume_scena` sare direct la scenă).
3. **Decizii creative = întrebări cu variante** (carusel de alegeri), cu o variantă recomandată. Tavi decide, Claude propune idei. Dă-i chestionarul întreg, nu amesteca subiecte (o dată un răspuns s-a amestecat cu chestionarul).
4. **Ce costă mult mai târziu se fixează acum** (mărimi, perspectivă, lumină, structura scenelor).
5. **Fără bani în plus:** ChatGPT (Codex), Gemini (Nano Banana, Veo, muzică) din abonamente. API-urile plătite rămân oprite. Cheile doar în secretele GitHub.
6. **Pe Mac:** nu ștergem nimic (mutăm în `_to_delete/`); descărcările din Gemini în Downloads sunt permise.

## 1. Calitate
- **Ținta e Steam.** Web-ul e doar previzualizare; nu reducem calitatea pentru web.
- **Mai bine fără animație decât una ieftină.** Respinse: animația „decupată” (cutout), pâlpâitul felinarului desenat din cod (chenar negru, apoi imagine stinsă calculată), cercurile/pietrele desenate ca forme geometrice. Dacă un efect nu arată real după o încercare bună, **oprește-l** și propune metoda Veo/art, nu mai cârpi.
- **Realismul primează**, apoi lizibilitatea: totul trebuie să se înțeleagă dintr-o privire și pe telefon (câinele prea întunecat/mic a trebuit refăcut).
- **Grila de pixeli e fixă (640×360), paleta e liberă.** Nu scalăm sprite-uri în joc; fiecare obiect se face la mărimea exactă din scenă din imaginea brută (`tools/art/scene_sprite.py`).

## 2. Personaje
- **Fiecare personaj are fața și corpul lui**, descrise explicit în prompt (formă a feței, nas, păr, barbă/mustață sau lipsa lor, constituție, postură). **Nu da niciodată foaia altui personaj ca referință** (toți ieșiseră clone ale lui Romică). Referință = doar foaia aceluiași personaj.
- **Nas roșu doar la băutori.** Siluetele trebuie să se deosebească și în umbră.
- **Înălțimi reale** (`height_cm`, 195 cm = 300 px pe foi). Proporții reale: un bătrân scund are ~6 capete înălțime, nu 7 (cerința „7 capete” a făcut-o pe Mioara caricatură).
- **Caracterul se vede prin detalii, nu prin exagerare:** Marius „de la țară cu aere de Germania” a ieșit întâi prea macho; corect: corp obișnuit, puțin moale, față de băiat, aerele în haine și atitudine.
- **ChatGPT pentru personaje** (realism); Gemini/Nano Banana iese prea „desen animat”.
- Nume schimbate: Tanti Veta → **Tanti Mioara**.

## 3. Romică (persoana întâi)
- **Nu are portret la dialog.** Se vede doar în oglindă și în ~5 momente-cheie din tot jocul (`Game.hero_portrait = true` doar atunci).
- **Nimeni nu e în două locuri:** cât timp portretul cuiva e în prim-plan, figura lui din scenă dispare (`figure()`).

## 4. Scene și compoziție
- **Scena trebuie pregătită pentru ce se întâmplă în ea.** Fiecare personaj/animal are un loc logic (câinele în ploaie nu avea sens → poarta cu streașină și banca la adăpost, câinele sub bancă). Dacă locul nu există în fundal, **refă fundalul** (editare cu ChatGPT, păstrând restul), nu-l pune „unde încape”.
- **Perspectivă:** fiecare fundal are `horizon` (ochii lui Romică la 1,55 m). Înălțime pe ecran = `(y_tălpi − horizon) × cm / 155`. Verifică cu uși, mese, scaune din fundal.
- **Lumina locului se aplică pe tot ce e pus peste fundal** (`lighting`, `shaders/scene_light.gdshader`): personajele trebuie să pară luminate ca obiectele din jur (Gina era prea roșie și saturată față de mașina de spălat → saturație și ambient pe figură).
- **Portretele și prim-planurile iau tonul scenei** (`grade`): cald și stins în casă, albăstrui noaptea.
- **Prim-planurile** (ex. câinele) sunt discrete: mai mici, nu stridente, cu fundalul puțin întunecat.
- **Obiecte care apar în scenă** (pietre, unelte) se desenează ca artă (ChatGPT, fundal verde), la perspectiva corectă; nu forme din cod.

## 5. Animație (Veo)
- Metoda aprobată: **imaginea exactă → Veo (Gemini) → `video_to_sprite.py`.**
- Imaginea de intrare **16:9, cu loc deasupra capului** (altfel Veo taie capul/șapca).
- **Bucla normală, nu dus-întors** (ping-pong respins). Dacă bucla nu se leagă, **o generare nouă**, cu promptul „revine exact la poza de început”.
- Promptul **nu folosește „flicker”/„failing”** (refuz); scrie „lumina tremură și scade din cauza unui contact slab”.
- Lumini care pâlpâie: **Veo pe tot fundalul**, apoi `tools/art/light_from_video.py` scoate imaginea stinsă și ritmul; lucrurile din lumina ei se întunecă odată cu ea.
- Gemini dă uneori erori/refuzuri și are limite pe zi: reîncearcă o dată cu alt prompt; nu insista.
- Personajele principale: așteptare + vorbit; secundare: așteptare (sau portret static până vine animația).

## 6. Atmosferă
- **Ploaia se vede peste tot unde e logic:** stropi care cad în aer (straturi de adâncime, luminați de felinare), stropi sparți pe jos, cercuri în băltoace, **picături pe geamuri** (doar pe sticlă, cu mască).
- **Sunet:** acasă lăutărească de la radio (înfundată), afară ploaie și sunete de sat (câini în depărtare etc.), în birt manele la televizor. Muzica se schimbă lin între scene.

## 7. Text și dialog
- Fontul **Jersey 15**, mărimea 20 (Pixelify era greu de citit). Verifică orice simbol nou în font (▼ lipsea → „>”).
- Sunet la derularea textului, cu „voce” diferită pe personaj.
- Replici scurte, oltenești unde e cazul („plecai”, „reparai”), satira pe situații și instituții, niciodată pe grupuri de oameni sau pe erou.

## 8. Ritm și gameplay
- **Prologul nu se termină în 2 minute.** Fiecare scenă are: ceva de găsit (obiecte/bani), un minijoc scurt, un dialog cu alegeri care contează puțin mai târziu, și câteva obiecte cu glume. Ieșirea din scenă se deblochează după ce le faci.
- Minijocurile au echivalent tactil (tap/tragere) și eșecul e comic, nu pedepsitor (o iei de la capăt).
- Indiciile vin din dialog (Gina îți spune unde ascunzi banii; Nea Ilie îți spune pe unde treci băltoaca).

## 9. Lecții tehnice
- Tap pe telefon: tratează doar `InputEventMouseButton`.
- Texturile web: max **4096 px** (sheet-urile de animație sunt grile).
- Exportul web: JSON-urile din `art/anim` incluse; cadrele separate, variantele `__x`, video-urile și sursele excluse.
- Procesarea video: nu ține toate cadrele în memorie (s-a închis procesul); mediane pe ~24 de cadre.
- Coada ChatGPT: după două încercări nereușite păstrează varianta ca `__respins` pentru Tavi; logo-urile/textul rămân motiv de respingere, la proporții fii tolerant.
- Mac: permisiunile de control expiră după 30 de minute fără activitate; în ChatGPT scrisul merge cu înlocuirea întregului câmp; extensia Chrome se poate deconecta (cere-i lui Tavi să deschidă Chrome).
