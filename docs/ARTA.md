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
- **Referințe** (`refs`): doar imagini proprii (foi de personaj, scene generate deja), ca să rămână personajele identice între scene. Fotografiile reale de pe internet se folosesc doar ca sursă de fapte în prompt, nu ca imagini de intrare.
- Plafon: maximum 4 imagini pe rulare, ca să nu apară facturi surpriză.
- Arta pe straturi: fundaluri **fără personaje**, iar personajele și obiectele interactive ca imagini separate, cu fundal transparent.
