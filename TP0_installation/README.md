# Rapport — TP0 : Python, uv, VS Code et Jupyter Notebook

**Module :** Système Distribué Agentique  
**Formation :** Master Intelligence Artificielle & Digital Computing (S3) — FST, Université Moulay Slimane  
**Année universitaire :** 2026–2027  
**Enseignant :** Lhoussaine Daoudi  
**Étudiant :** ELAALGI Hatim  
**Sujet :** guide *instalation_de_python_et_uv.pdf* (TP0 « python + uv »)

---

## 1. Objectifs

Le guide fourni prépare l'environnement de travail utilisé pendant tout le module :
- installer **uv**, le gestionnaire de projets et de paquets Python ;
- créer un projet (`uv init`) et un environnement virtuel local (`uv venv`) ;
- installer `ipykernel`, `pandas`, `matplotlib` et `seaborn` ;
- enregistrer un kernel Jupyter et exécuter un notebook *Hello World* dans VS Code ;
- exécuter un script de production `app.py` avec `uv run`.

## 2. Choix de réalisation : un environnement conteneurisé

J'ai réalisé les étapes du guide **dans une image Docker** plutôt que directement sous Windows. Le `.venv` créé par uv vit dans le conteneur, et VS Code se connecte au kernel de ce conteneur par `localhost`.

Ce choix apporte trois avantages :
- un **environnement identique pour tous les TP** : les TP2 à TP4 ont simplement ajouté leurs bibliothèques au même `pyproject.toml` ;
- la **reproductibilité** : `uv.lock` fixe la version exacte de chaque bibliothèque, et `docker compose build` reconstruit l'image à l'identique sur n'importe quelle machine ;
- une **machine hôte propre** : seuls Docker Desktop et VS Code y sont installés.

### Architecture

```
VS Code (Windows) ── http://localhost:8888 ──► Jupyter Lab (conteneur) ──► kernel « Python (uv-env) »
                                                                            └── /app/.venv (uv, Python 3.14)
```

Le fichier [`compose.yaml`](../compose.yaml) définit deux services :
- `lab` : un serveur Jupyter permanent, pour travailler dans VS Code ;
- `notebook` : l'exécution d'un notebook sans interface (`jupyter nbconvert --execute --inplace`), qui écrit les sorties dans le notebook lui-même.

## 3. Travail réalisé : correspondance avec le guide

| Étape du guide | Commande du guide | Réalisation dans le conteneur |
|---|---|---|
| 1. Installer uv | `irm https://astral.sh/uv/install.ps1 \| iex` | image de base `ghcr.io/astral-sh/uv:bookworm-slim` ([Dockerfile](../Dockerfile)) |
| 2. Initialiser le projet | `uv init`, `uv venv` | [`pyproject.toml`](../pyproject.toml) et `RUN uv venv` |
| 3. Activer l'environnement | `.venv\Scripts\activate` | `ENV VIRTUAL_ENV=/app/.venv` et `PATH=/app/.venv/bin:$PATH` |
| 4. Installer les bibliothèques | `uv add ipykernel pandas matplotlib seaborn` | dépendances du `pyproject.toml`, installées par `uv sync --locked` à partir de [`uv.lock`](../uv.lock) |
| 4 bis. Enregistrer le kernel | `python -m ipykernel install --name=python_uv_workspace --display-name "Python (uv-env)"` | même commande dans le Dockerfile (option `--sys-prefix`) |
| 5. Configurer VS Code | extensions Python et Jupyter | identique, sur la machine hôte |
| 6. Notebook Hello World | `hello.ipynb` | [`hello.ipynb`](hello.ipynb) |
| 7. Production | `uv run app.py` | [`app.py`](app.py), exécuté avec l'interpréteur du `.venv` du conteneur |

## 4. Résultats

### 4.1 Notebook `hello.ipynb`

| Vérification | Résultat obtenu |
|---|---|
| Cellule du guide | `Hello World avec uv et VS Code !` |
| Version de Python | 3.14.3 |
| Interpréteur utilisé | `/app/.venv/bin/python`, c'est-à-dire le `.venv` créé par uv |
| Système | Linux (noyau WSL2) : le code s'exécute bien dans le conteneur |
| Bibliothèques de l'étape 4 | ipykernel 7.4.0, pandas 3.0.6, matplotlib 3.11.2, seaborn 0.13.2 |

### 4.2 Script `app.py`

Le script affiche le DataFrame de test (4 catégories) et produit le graphique de validation :

![Validation de l'environnement uv](validation_uv.png)

## 5. Difficultés rencontrées et solutions

| Problème | Cause | Solution |
|---|---|---|
| VS Code ne se connecte pas au serveur Jupyter (`_xsrf argument missing`) | le serveur refuse les requêtes sans jeton | jeton fixe `JUPYTER_TOKEN=uv-docker` et URL `http://localhost:8888/?token=uv-docker` |
| `plt.show()` n'ouvre aucune fenêtre | le conteneur n'a pas d'écran | `app.py` enregistre aussi le graphique (`plt.savefig`) |
| Graphiques absents dans les notebooks sans `%matplotlib inline` | la variable `MPLBACKEND=Agg` de l'image remplace l'affichage intégré de Jupyter | variable supprimée : hors notebook, matplotlib choisit seul le mode sans écran |
| Échec du téléchargement des modèles d'embedding (TP4) | le protocole de téléchargement Xet de Hugging Face échoue dans le conteneur | `HF_HUB_DISABLE_XET=1` dans `compose.yaml` |
| Code du guide incomplet | `'Valeurs':}` sans liste de valeurs ; lien `https://astral.sh` sans le nom du script | quatre valeurs ajoutées ; script `https://astral.sh/uv/install.ps1` (Windows) ou `install.sh` (macOS / Linux) |

## 6. Utilisation

```bash
docker compose build                                         # construire l'image (après chaque changement de pyproject.toml)
docker compose up -d lab                                     # serveur Jupyter sur http://localhost:8888
docker compose run --rm --entrypoint python notebook TP0_installation/app.py  # étape 7 du guide
docker compose run --rm notebook TP0_installation/hello.ipynb                 # exécuter un notebook sans interface
docker compose down                                          # arrêter le serveur
```

Dans VS Code : **Select Kernel → Select Another Kernel… → Existing Jupyter Server…** → `http://localhost:8888/?token=uv-docker` → **Python (uv-env)**.

## 7. Conclusion

Toutes les étapes du guide sont réalisées : uv gère Python 3.14 et les bibliothèques, le kernel « Python (uv-env) » est utilisable depuis VS Code, et le notebook comme le script s'exécutent correctement. La conteneurisation ajoute la reproductibilité : la même image, décrite par `pyproject.toml` et `uv.lock`, a servi à exécuter tous les TP du module.
