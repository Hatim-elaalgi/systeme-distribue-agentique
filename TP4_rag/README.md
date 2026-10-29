# TP4 — Système RAG sur mon CV : résultats

Notebook : [TP4_RAG.ipynb](TP4_RAG.ipynb). Document indexé : mon CV, [`pdfs/CV_ELAALGI_Hatim_2026_FR_Global.pdf`](pdfs/CV_ELAALGI_Hatim_2026_FR_Global.pdf) (2 pages), comme le propose le prof.

## Pipeline

| Étape | Choix |
|---|---|
| Chargement | `PyPDFLoader` |
| Découpage | `RecursiveCharacterTextSplitter`, 300 tokens, overlap 20 (paramètres du prof) → **12 chunks** de 257 à 291 tokens (un de 33 tokens en fin de page 1) |
| Embeddings | FastEmbed local `paraphrase-multilingual-MiniLM-L12-v2` (384 dimensions) |
| Base vectorielle | Chroma (`./store`) |
| Retriever | similarité, **k = 5** |
| LLM du RAG | Groq `qwen/qwen3.8-27b` |
| LLM juge | Groq `openai/gpt-oss-120b` (plus puissant que le LLM du RAG, comme le demande le prof) |

**Bug du code du prof :** `search_Kwargs={'k',5}` (K majuscule, et un ensemble au lieu d'un dictionnaire) est ignoré. Le retriever renvoie **4 chunks** au lieu de 5. Avec `search_kwargs={'k': 5}`, il en renvoie bien 5.

## Évaluation sur 9 questions

| Question | Bon chunk dans le top 5 | Réponse du RAG | Exacte | Fidélité (juge) |
|---|---|---|---|---|
| Master et date du diplôme | oui | Master IA & Digital Computing, juin 2027 | oui | 5/5 |
| Entreprise et projet actuels | oui | Synertic, copilote d'investigation de sécurité à base d'agents LLM | oui | 5/5 |
| PFE de Licence | oui | Chatbot ATLAS | oui | **1/5** |
| Résultats du VAE (fraude) | oui | AUC-PR 0,1139 vs 0,0497 (+129 %), rappel 44,2 %, coût −24 % | oui | 5/5 |
| Clients de NIDS-FL | **non** | « Je ne sais pas ! » | non (3 clients) | 1/5 |
| Langues | oui | arabe (maternelle), français (courant), anglais (intermédiaire) | oui | 5/5 |
| Avatar 3D d'Ibn Battuta | oui | Three.js | oui | 5/5 |
| Date de naissance (absente du CV) | — | « Je ne sais pas ! » | oui | 5/5 |
| Capitalisation boursière (hors sujet, question du prof) | — | « Je ne sais pas ! » | oui | 2/5 |

- **6 questions sur 7** dont la réponse est dans le CV reçoivent une réponse exacte, sans rien inventer.
- **Pas d'hallucination :** « Je ne sais pas ! » pour la question absente et pour la question hors sujet.
- **Le seul échec vient du retrieval.** Le LLM n'a jamais vu l'information sur NIDS-FL.

## Combien de chunks faut-il ? (rang du chunk qui contient la réponse)

| k | questions dont le bon chunk est retrouvé |
|---|---|
| 1 | 2 / 7 |
| 3 | 4 / 7 |
| 4 (code du prof) | 6 / 7 |
| 5 | 6 / 7 |
| 12 (tout le CV) | 7 / 7 |

MRR = 0.52. Pour NIDS-FL, le bon chunk n'arrive qu'au **rang 7**. PyPDF n'extrait pas le texte dans l'ordre visuel du CV : le titre « NIDS-FL » se trouve à la fin du chunk 1, alors que sa description (« FedAvg sur 3 clients ») est dans le chunk 5, sans le nom du projet. PyPDF sépare aussi les mots par des **tabulations**.

## Limites du LLM juge
- **Faux négatif :** 1/5 pour la réponse « Chatbot ATLAS », qui est exacte et présente dans le contexte. Le juge n'a pas relié le titre du projet à la ligne « Projet de fin d'études de Licence ».
- **Incohérence :** la même réponse « Je ne sais pas ! » obtient 5/5, 2/5 et 1/5 selon la question. La métrique (« la réponse doit être dérivée uniquement du contexte ») ne dit pas comment noter une abstention.
- Le juge mesure la **fidélité au contexte**, pas l'**exactitude**.

## Conclusions
- La qualité d'un RAG dépend d'abord du **retrieval**, et le retrieval de la **préparation du document**. Pour un CV, il vaudrait mieux nettoyer le texte et découper **par section ou par projet**, plutôt qu'à taille fixe.
- Le prompt « Je ne sais pas ! » protège efficacement contre les hallucinations.
- Un LLM juge automatise l'évaluation, mais il faut le vérifier : sa métrique doit préciser comment noter une abstention, et une métrique d'exactitude doit le compléter.
