# Bruno Runner pour Zed

Extension [Zed](https://zed.dev) pour écrire **et exécuter** des requêtes [Bruno](https://www.usebruno.com/) sans quitter l'éditeur.

Formats supportés :

- **`.bru`** : format historique de Bruno (collection avec `bruno.json`)
- **`.yml`** : nouveau format YAML [OpenCollection](https://www.opencollection.com/) (collection avec `opencollection.yml`)

## Fonctionnalités

- **Coloration syntaxique `.bru`** via [`tree-sitter-bruno`](https://github.com/Scalamando/tree-sitter-bruno)
  - injection de langage : JSON dans `body:json` / `body:graphql:vars`, JavaScript dans `script:pre-request` / `script:post-response` / `tests`, XML, GraphQL, SPARQL, Markdown dans `docs`
  - outline (`ctrl-shift-o`) et correspondance des accolades
- **Bouton ▶ dans la marge** à côté du bloc `get {` / `post {` / `put {`… d'un `.bru`, qui lance la requête
- **Tâches Zed** : lancer la requête, le dossier, la collection entière, choisir l'environnement
- **Réponse lisible dans le terminal Zed** : méthode, URL, statut coloré, temps, taille, body JSON formaté, plus les résultats des tests et assertions de `bru`
- **Environnement mémorisé par collection** (`local`, `staging`, `prod`…)
- **Vue graphique de la réponse** dans Zed via l'aperçu Markdown : statut, temps, body, tests, headers, query params

Exemple de sortie :

```
collection: /home/me/api/my-collection
environment: local
$ bru run /home/me/api/my-collection/users/get-users.bru --env local --reporter-json …

users/get-users (200 OK) - 12 ms
Tests
   ✓ returns json
Assertions
   ✓ res.status: eq 200

━━ Get users users/get-users
GET http://localhost:3000/users
200 OK  12 ms · 69 B
{
  "id": 1,
  "name": "Shalom"
}
```

## Prérequis

- Zed
- Node.js
- Le CLI Bruno :

```sh
npm i -g @usebruno/cli
bru --version
```

## Installation

### 1. Cloner et installer le lanceur

```sh
git clone git@github.com:CianusDev/zed-bruno.git
cd zed-bruno
./install.sh
```

`install.sh` crée le lien `~/.local/bin/bruno-zed` vers `bin/bruno-zed`, le petit lanceur Node qui entoure `bru run`. Vérifie que `~/.local/bin` est dans ton `PATH`.

### 2. Installer l'extension dans Zed

`ctrl-shift-p` → **`zed: install dev extension`** → sélectionner le dossier `zed-bruno`.

Zed télécharge et compile la grammaire tree-sitter. Les fichiers `.bru` sont alors reconnus comme langage **Bruno**.

### 3. Tâches globales (nécessaire pour les `.yml`)

L'extension fournit seulement la tâche du bouton ▶ pour les `.bru`. Pour avoir toutes les commandes, y compris sur les fichiers YAML, copie [`zed-config/tasks.json`](zed-config/tasks.json) dans `~/.config/zed/tasks.json`. Si tu as déjà ce fichier, fusionne les entrées.

```sh
cp zed-config/tasks.json ~/.config/zed/tasks.json
```

### 4. Raccourcis clavier (optionnel)

Ajoute le contenu de [`zed-config/keymap.json`](zed-config/keymap.json) dans `~/.config/zed/keymap.json`. Les raccourcis ne sont actifs que dans les fichiers `.bru`, `.yml` et `.yaml`.

```json
{
  "context": "Editor && (extension == bru || extension == yml || extension == yaml)",
  "bindings": {
    "ctrl-alt-r": ["task::Spawn", { "task_name": "Bruno: run request" }],
    "ctrl-alt-f": ["task::Spawn", { "task_name": "Bruno: run folder" }],
    "ctrl-alt-c": ["task::Spawn", { "task_name": "Bruno: run collection" }],
    "ctrl-alt-e": ["task::Spawn", { "task_name": "Bruno: choose environment" }],
    "ctrl-alt-v": ["task::Spawn", { "task_name": "Bruno: open response view" }]
  }
}
```

## Utilisation

Ouvre un fichier de requête dans une collection Bruno, puis :

| Action | Raccourci | Tâche (`task: spawn`) |
|---|---|---|
| Lancer la requête courante | `ctrl-alt-r` ou ▶ dans la marge (`.bru`) | `Bruno: run request` |
| Lancer toutes les requêtes du dossier (récursif) | `ctrl-alt-f` | `Bruno: run folder` |
| Lancer toute la collection | `ctrl-alt-c` | `Bruno: run collection` |
| Choisir l'environnement | `ctrl-alt-e` | `Bruno: choose environment` |
| Ouvrir la vue de la réponse | `ctrl-alt-v` | `Bruno: open response view` |

`task: rerun` relance la dernière tâche.

### Vue de la réponse (aperçu Markdown)

Après chaque exécution, `bruno-zed` écrit `~/.local/state/bruno-zed/response.md` :

- un tableau récapitulatif quand plusieurs requêtes ont tourné (dossier, collection)
- pour chaque requête : statut, temps, taille, body de la réponse formaté (JSON, HTML, XML…), tests et assertions, headers de réponse, puis la requête envoyée (query params, headers, body)

Au premier run, le fichier s'ouvre dans Zed. Lance une fois **`markdown: open preview to the side`** (`ctrl-shift-p`) : l'aperçu reste ouvert et se met à jour tout seul à chaque nouvelle exécution, puisque le fichier est réécrit au même endroit.

Si tu fermes l'onglet, `ctrl-alt-v` (`Bruno: open response view`) le rouvre.

Les extensions Zed n'ont pas d'API de webview ni de panneau personnalisé. Cet aperçu Markdown est donc en lecture seule : la requête s'édite dans le fichier `.bru` ou `.yml`.

### Détection de la collection

Le lanceur remonte les dossiers parents du fichier jusqu'à trouver `opencollection.yml` (format YAML) ou `bruno.json` (format `.bru`). `bru` est ensuite exécuté depuis cette racine, ce qui est obligatoire pour que le CLI charge la collection, les environnements et les scripts de collection.

### Environnements

Les environnements sont lus dans `<collection>/environments/` (`*.bru` ou `*.yml`).

`Bruno: choose environment` affiche la liste et attend un numéro dans le terminal. Le choix est enregistré **par collection** dans `~/.local/state/bruno-zed/envs.json`.

Ordre de priorité :

1. Variable d'environnement `BRUNO_ENV` (`BRUNO_ENV=none` désactive l'environnement)
2. Choix enregistré avec `Bruno: choose environment`
3. Sinon, défaut de la collection (`presets.defaultEnvironment`) appliqué par `bru`

## Lanceur `bruno-zed` en ligne de commande

Le lanceur s'utilise aussi hors de Zed :

```sh
bruno-zed run <fichier>          # une requête
bruno-zed folder <chemin>        # tout le dossier (récursif)
bruno-zed collection <chemin>    # toute la collection contenant <chemin>
bruno-zed env <chemin>           # choisir l'environnement de la collection
bruno-zed view                   # ouvrir la vue Markdown de la dernière réponse dans Zed
bruno-zed last                   # réafficher la dernière réponse (JSON complet)
```

Les arguments placés après `--` sont transmis tels quels à `bru run` :

```sh
bruno-zed run users/get.bru -- --insecure --env-var token=abc
```

### Variables de configuration

| Variable | Effet |
|---|---|
| `BRUNO_ENV=<nom>` | force l'environnement (`none` = aucun) |
| `BRUNO_ZED_HEADERS=1` | affiche aussi les headers de réponse |
| `BRUNO_ZED_BODY=0` | n'affiche pas le body dans le terminal |
| `BRUNO_ZED_VIEW=0` | ne génère pas la vue Markdown |
| `BRUNO_ZED_OPEN=first\|always\|never` | quand ouvrir la vue dans Zed (défaut `first` : seulement si elle n'existe pas encore) |

Pour les appliquer depuis Zed, ajoute-les au champ `env` d'une tâche :

```json
{
  "label": "Bruno: run request (headers)",
  "command": "bruno-zed",
  "args": ["run", "$ZED_FILE"],
  "env": { "BRUNO_ZED_HEADERS": "1" }
}
```

### Fichiers générés

- `~/.local/state/bruno-zed/response.md` : vue Markdown de la dernière exécution
- `~/.local/state/bruno-zed/last-response.json` : dernière requête et réponse complètes (headers, body)
- `~/.local/state/bruno-zed/last-report.json` : rapport JSON brut de `bru`
- `~/.local/state/bruno-zed/envs.json` : environnement choisi pour chaque collection

## Structure du dépôt

```
extension.toml              manifeste de l'extension + grammaire tree-sitter
languages/bruno/
  config.toml               langage "Bruno" pour *.bru
  highlights.scm            coloration
  injections.scm            JSON / JS / XML / GraphQL / Markdown embarqués
  outline.scm, brackets.scm
  runnables.scm             ▶ sur le bloc HTTP (tag bruno-request)
  tasks.json                tâche liée au ▶
bin/bruno-zed               lanceur Node autour de `bru run`
install.sh                  lien bruno-zed -> ~/.local/bin
zed-config/                 tasks.json et keymap.json à copier dans ~/.config/zed
```

## Limites connues

- **Pas de ▶ pour les `.yml`** : une extension Zed ne peut pas ajouter de runnables au langage YAML intégré. Utilise `ctrl-alt-r` ou `task: spawn`.
- **Pas de coloration propre aux `.yml` Bruno** : ils gardent la coloration YAML standard de Zed.
- La grammaire `tree-sitter-bruno` date de 2024 : certains blocs récents (`settings {}`, `body:ws`, `auth:oauth2` avancé…) ne sont pas colorés. L'exécution n'est pas affectée.
- Pas d'interface graphique éditable comme l'app Bruno : Zed n'offre pas de webview aux extensions. La vue de la réponse est un aperçu Markdown en lecture seule.
- Le choix d'environnement se fait dans le terminal Zed (saisie d'un numéro), car les tâches Zed ne peuvent pas ouvrir de menu natif.

## Dépannage

- **`bruno-zed: command not found`** : relance `./install.sh` et vérifie que `~/.local/bin` est dans le `PATH` du shell utilisé par Zed.
- **`` `bru` not found ``** : `npm i -g @usebruno/cli`. Avec nvm, vérifie que Node est chargé par ton shell de connexion.
- **`No Bruno collection found`** : le fichier n'est pas dans un dossier qui contient (lui ou un parent) `bruno.json` ou `opencollection.yml`.
- **Variables `{{baseUrl}}` non résolues** : aucun environnement sélectionné. Lance `Bruno: choose environment`.
- **Le ▶ n'apparaît pas** : vérifie que le langage affiché en bas à droite est bien **Bruno**, puis reconstruis l'extension (page Extensions → bouton **Rebuild** de l'extension de dev).

## Crédits

- Grammaire : [Scalamando/tree-sitter-bruno](https://github.com/Scalamando/tree-sitter-bruno) (MIT)
- [Bruno](https://github.com/usebruno/bruno) et son CLI `@usebruno/cli`

## Licence

[MIT](LICENSE)
