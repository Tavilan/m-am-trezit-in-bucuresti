# Instrucțiuni pentru ChatGPT (Codex) pe Mac-ul lui Tavi: coada de artă

Folosești generarea de imagini inclusă în abonamentul ChatGPT ($imagegen). **Nu folosi API-ul și nici OPENAI_API_KEY.**

1. În `~/Projects/m-am-trezit-in-bucuresti/joc` (dacă nu există: `git clone https://github.com/Tavilan/m-am-trezit-in-bucuresti ~/Projects/m-am-trezit-in-bucuresti/joc`), rulează `git pull`.
2. Citește `docs/HANDBOOK.md` (secțiunile 1–4) și `art/QUEUE.md`. Fiecare rând nebifat `- [ ] <id>` e o imagine de făcut.
3. Pentru fiecare: deschide `art/prompts/<id>.json`. Promptul final = conținutul `art/prompts/_style.md` + câmpul `prompt`. Dacă există `refs`, folosește acele fișiere ca imagini de referință (același personaj); dacă `art/raw/<x>.png` nu există încă, folosește `art/inbox/<x>.png` generat mai devreme în aceeași rulare. Fă imaginile în ordinea din coadă. Pentru `"type": "character"`: fundal verde plin #00FF00 (portretele `*_portret` în format lat 16:9, cum scrie în prompt). Pentru `"type": "object"`: tot fundal verde plin #00FF00. Pentru `"type": "scene"`: format lat 16:9.
4. Generează **o singură** imagine cu $imagegen și salveaz-o ca `art/inbox/<id>.png`. Nu o modifica, nu o pixeliza (se ocupă GitHub).
5. Verifică imaginea față de prompt (fără text, fără logo-uri sau mărci, fundal verde la personaje). Dacă încalcă o regulă, **regenerează o singură dată**, cu cerința încălcată spusă explicit în prompt. Dacă nici a doua oară nu e bună, salveaz-o pe cea mai bună dintre cele două ca `art/inbox/<id>__respins.png` (o judecă Tavi), scrie motivul sub rând și **treci la următoarea** (nu opri toată coada). Logo-urile sau textul rămân motiv de respingere; la proporții și detalii mărunte fii tolerant: important e să semene cu descrierea.
6. Bifează rândul în `art/QUEUE.md` (`- [x] <id>`), apoi imediat `git add art/inbox art/QUEUE.md && git commit -m "Artă din coadă: <id>" && git pull --rebase && git push` (după fiecare imagine, ca să nu se piardă nimic).
7. Doar dacă generarea de imagini nu e disponibilă deloc: scrie motivul în `art/QUEUE.md` și oprește-te; nu încerca altă metodă (fără API, fără chei).
