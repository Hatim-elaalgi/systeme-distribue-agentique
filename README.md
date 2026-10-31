# Système Distribué Agentique — Travaux pratiques (TP0 à TP5)

**Étudiant :** ELAALGI Hatim — Master S3

Tous les notebooks sont exécutés dans le même environnement : un conteneur Docker qui reprend le guide uv du TP0, et dont le kernel Jupyter est accessible depuis VS Code par `localhost`.

| Dossier | Contenu | Rapport |
|---|---|---|
| [TP0_installation](TP0_installation/) | Guide Python + uv + Jupyter, réalisé dans un conteneur Docker ; `hello.ipynb` et `app.py` | [Rapport](TP0_installation/README.md) |
| [TP1_python](TP1_python/) | Rappels Python (partie 1) : conversions, conditions, boucles, fonctions, listes, configuration d'un système multi-agents | [Rapport](TP1_python/README.md) |
| [TP2_mesa](TP2_mesa/) | Mesa 3 : formation de l'opinion publique, réponses argumentées et mesurées aux 8 questions | [Rapport](TP2_mesa/README.md) |
| [TP3_prompt](TP3_prompt/) | Tokens (`tiktoken`), appel d'un LLM (Groq), analyse de sentiment zero-shot / few-shot / CoT évaluée au micro-F1 | [Rapport](TP3_prompt/README.md) |
| [TP4_rag](TP4_rag/) | RAG sur mon CV (Chroma, FastEmbed), évaluation par un LLM juge | [Rapport](TP4_rag/README.md) |
| [TP5_agents](TP5_agents/) | Agents LangChain : mémoire (PostgreSQL), outils (web, Python REPL), middleware, RAG comme outil, garde-fous | [Rapport](TP5_agents/README.md) |

## Résultats principaux

- **TP2** — Une règle locale (se rapprocher de la moyenne de ses voisins) produit un consensus global ; α ne règle que la vitesse (7 ticks pour α = 1, plus de 200 pour α = 0.01). Avec un biais de confirmation, on passe à la polarisation (ε = 0.15) puis à la fragmentation (ε = 0.05). Sur un graphe Barabási-Albert, 5 influenceurs têtus font passer l'opinion moyenne de 0.49 à 0.94, contre 0.55 pour 5 utilisateurs isolés.
- **TP3** — Sur 20 critiques gold, les trois prompts obtiennent 0.90 avec un petit modèle (`allam-2-7b`) comme avec un plus grand (`qwen3.8-27b`), mais sans faire les mêmes erreurs. Sur 10 tirages, le few-shot et le CoT obtiennent 0.915 ± 0.032 : le gain sur le zero-shot est plus petit que la variabilité due aux exemples. Les erreurs restantes viennent du sarcasme et des avis mitigés.
- **TP4** — Le RAG répond juste à 6 des 7 questions dont la réponse est dans le CV, et répond « Je ne sais pas ! » aux questions absentes ou hors sujet. Le seul échec vient de l'extraction du PDF, qui sépare un projet de sa description. Le LLM juge n'est pas toujours cohérent : 1/5 pour une réponse exacte, et trois notes différentes pour la même abstention.
- **TP5** — L'agent enchaîne et corrige seul ses appels d'outils : il contourne l'absence de sympy pour résoudre $6x^2 + 11x - 6 = 0$, et relance 7 recherches web quand l'outil ne renvoie qu'un résultat. La mémoire vient du checkpointer (RAM ou PostgreSQL), pas du modèle. Utilisé comme outil sans consigne restrictive, le RAG hallucine (affiliation et diplôme inventés). Le *human-in-the-loop* ne se déclenche que si l'outil sensible est réellement appelé.

## Lancer

```bash
cp .env.example .env              # puis coller sa clé Groq (TP3 et TP4)
docker compose build
docker compose up -d lab          # kernel Jupyter : http://localhost:8888/?token=uv-docker
docker compose run --rm notebook TP2_mesa/TP2Mesa_Simulation_MA.ipynb   # exécuter un notebook sans interface
```

Dans VS Code : **Select Kernel → Existing Jupyter Server** → `http://localhost:8888/?token=uv-docker` → **Python (uv-env)**. Le détail est dans [TP0_installation/README.md](TP0_installation/README.md).

Les réponses du LLM du TP3 sont enregistrées dans `TP3_prompt/data/cache_llm.json` : le notebook se ré-exécute à l'identique sans nouvel appel à l'API.
