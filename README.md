# Système Distribué Agentique — Travaux pratiques (TP0 à TP4)

**Étudiant :** ELAALGI Hatim — Master S3

| Dossier | Contenu | État |
|---|---|---|
| [TP0_installation](TP0_installation/) | Guide uv + Jupyter, réalisé dans un conteneur Docker (kernel sur `localhost:8888`) | exécuté |
| [TP1_python](TP1_python/) | Rappels Python (partie 1) | exécuté |
| [TP2_mesa](TP2_mesa/) | Mesa 3 : formation de l'opinion, réponses aux 8 questions | exécuté |
| [TP3_prompt](TP3_prompt/) | Tokens, appel LLM (Groq), analyse de sentiment zero-shot / few-shot / CoT | à exécuter |
| [TP4_rag](TP4_rag/) | RAG sur mon CV + LLM juge | à exécuter |

## Lancer

```bash
cp .env.example .env              # puis coller sa clé Groq
docker compose build
docker compose up -d lab          # kernel Jupyter : http://localhost:8888/?token=uv-docker
docker compose run --rm notebook TP3_prompt/TP3_prompt.ipynb   # exécute un notebook sans interface
```

Les réponses du LLM du TP3 sont mises en cache dans `TP3_prompt/data/cache_llm.json` : une exécution interrompue reprend là où elle s'était arrêtée.
