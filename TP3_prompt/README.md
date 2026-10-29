# TP3 — Prompt Engineering : résultats

Notebook : [TP3_prompt.ipynb](TP3_prompt.ipynb). Le LLM est appelé via l'API **Groq** (gratuite), à la place d'OpenAI. Les 520 réponses du modèle sont enregistrées dans [`data/cache_llm.json`](data/cache_llm.json), et les 20 critiques gold dans [`data/gold_examples.json`](data/gold_examples.json).

## Partie 1 — Tokens (`tiktoken`, encodage `o200k_base`)

Le prompt du prof « Vous êtes un expert en marketing digital. C'est quoi un digital marketer ? » donne **16 tokens** : `Vous| êtes| un| expert| en| marketing| digital|.| C|'est| quoi| ...`

Test personnel, la même phrase en trois langues :

| Langue | Mots | Tokens | Découpage |
|---|---|---|---|
| anglais | 10 | **12** | `I| am| a| master's| student| in| artificial| intelligence| in| Tang|ier|.` |
| français | 9 | **13** | `... d|'int|elligence| artific|ielle| à| Tanger|.` |
| arabe | 8 | **16** | `... الذ|ك|اء| الاص|ط|نا|عي| ...` |

Le vocabulaire est surtout fait de morceaux de mots anglais : à contenu égal, un prompt en français ou en arabe coûte plus de tokens.

## Partie 2 — Appel d'un LLM
`ChatGroq(model="qwen/qwen3.8-27b", temperature=0)`, avec les messages du prof (system « expert en marketing digital », user « C'est quoi un digital marketer ? »). L'appel a consommé **31 tokens de prompt et 714 tokens de réponse**. Le modèle compte plus de tokens que `tiktoken` (14), car Qwen a son propre tokeniseur et ajoute des tokens de formatage autour de chaque message.

## Partie 3 — Analyse de sentiment (protocole du PDF)

**Métrique.** Le PDF donne 0,870 comme micro-F1 de son exemple (TP = 50, FP = 10, FN = 5, TN = 100). C'est en fait le F1 de la **classe positive** seule. Le micro-F1 sur les deux classes vaut **0,909**, comme l'accuracy : c'est toujours le cas quand chaque exemple reçoit une seule étiquette.

**Données.** `dataset_imdb.zip` : 50 000 critiques équilibrées. Je garde les critiques de 80 mots au plus (4 217), à cause de la fenêtre de 4 096 tokens du petit modèle et du quota gratuit. Découpage 80 / 20 (`random_state=42`), puis **20 critiques gold** (11 négatives, 9 positives).

**Prompts** (texte du PDF) : zero-shot (~49 tokens), few-shot avec 8 exemples équilibrés et mélangés (~663 tokens), CoT few-shot (~720 tokens).

### Évaluation unique (micro-F1 sur 20 critiques gold)

| Modèle | zero-shot | few-shot | CoT few-shot |
|---|---|---|---|
| `allam-2-7b` (7 milliards de paramètres) | 0.90 | 0.90 | 0.90 |
| `qwen/qwen3.8-27b` (27 milliards) | 0.90 | 0.90 | 0.90 |

Même score partout, mais **pas les mêmes erreurs**. Quatre critiques sont concernées :

| Critique (vraie étiquette) | Difficulté | Qui se trompe |
|---|---|---|
| « THE greatest Mob/Crime film... and I have the brain capacity of an earth worm » (negative) | **sarcasme** | les 6 combinaisons |
| « I gave it an 8 only because... really about a 5.5 » (positive) | avis mitigé | allam zero-shot, qwen few-shot et CoT |
| « his least successful film... almost worth seeing » (negative) | critique nuancée | allam few-shot et CoT : répond **`mixed`** |
| « the stupidest movie... If you want a laugh, rent this » (negative) | conseillé pour en rire | qwen zero-shot |

Avec les exemples few-shot, le petit modèle a inventé l'étiquette `mixed`, interdite par la consigne. Il classait correctement cette critique en zero-shot.

### Évaluations répétées (10 tirages d'exemples, `allam-2-7b`)

| Prompt | micro-F1 moyen | écart-type | min – max |
|---|---|---|---|
| zero-shot | 0.90 | — | — |
| few-shot | **0.915** | 0.032 | 0.85 – 0.95 |
| CoT few-shot | **0.915** | 0.032 | 0.85 – 0.95 |

![Variabilité few-shot / CoT](figures/variabilite_few_shot_cot.png)

## Conclusions
- Le score dépend des exemples tirés (de 1 à 3 erreurs sur 20) : il faut répéter l'évaluation, comme le demande le PDF.
- Le gain du few-shot sur le zero-shot (+0.015) est **plus petit que l'écart-type** (0.032). Avec 20 critiques gold, une critique vaut 0.05 point : on ne peut pas départager les prompts.
- Les erreurs viennent surtout des **données** (sarcasme, avis mitigés, étiquettes discutables), pas du prompt.
- Le few-shot coûte environ 13 fois plus de tokens que le zero-shot, pour un gain non mesurable ici.

## Corrections et écarts par rapport au PDF
- **Bug de la boucle répétée :** le PDF ajoute le score few-shot dans la liste CoT (`cot_few_shot_performance.append(few_shot_micro_f1)`), donc le CoT n'est jamais évalué. Ici, il est évalué séparément : ses scores diffèrent du few-shot aux répétitions 7 et 10.
- Groq (`allam-2-7b`, `qwen/qwen3.8-27b`) au lieu d'OpenAI `gpt-5.2`, critiques de 80 mots au plus, et un `random_state` dans `create_examples` pour la reproductibilité.
