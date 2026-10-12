# Instrucțiuni pentru ChatGPT (Codex) pe Mac-ul lui Tavi: coada de artă

Folosești generarea de imagini inclusă în abonamentul ChatGPT ($imagegen). **Nu folosi API-ul și nici OPENAI_API_KEY.**

1. În `~/Projects/m-am-trezit-in-bucuresti/joc` (dacă nu există: `git clone https://github.com/Tavilan/m-am-trezit-in-bucuresti ~/Projects/m-am-trezit-in-bucuresti/joc`), rulează `git pull`.
2. Citește `art/QUEUE.md`. Fiecare rând nebifat `- [ ] <id>` e o imagine de făcut.
3. Pentru fiecare: deschide `art/prompts/<id>.json`. Promptul final = conținutul `art/prompts/_style.md` + câmpul `prompt`. Dacă există `refs`, folosește acele fișiere ca imagini de referință (același personaj); dacă `art/raw/<x>.png` nu există încă, folosește `art/inbox/<x>.png` generat mai devreme în aceeași rulare. Fă imaginile în ordinea din coadă. Pentru `"type": "character"`: fundal verde plin #00FF00. Pentru `"type": "scene"`: format lat 16:9.
4. Generează **o singură** imagine cu $imagegen și salveaz-o ca `art/inbox/<id>.png`. Nu o modifica, nu o pixeliza (se ocupă GitHub).
5. Bifează rândul în `art/QUEUE.md` (`- [x] <id>`).
6. `git add art/inbox art/QUEUE.md && git commit -m "Artă din coadă: <id-uri>" && git push`.
7. Dacă imagine-generarea nu e disponibilă sau ceva eșuează, nu încerca altă metodă: scrie motivul în `art/QUEUE.md`, sub rândul respectiv, și oprește-te.
