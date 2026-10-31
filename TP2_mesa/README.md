# Rapport — TP2 : Simulation multi-agents avec Mesa 3

**Module :** Système Distribué Agentique  
**Formation :** Master Intelligence Artificielle & Digital Computing (S3) — FST, Université Moulay Slimane  
**Année universitaire :** 2026–2027  
**Enseignant :** Lhoussaine Daoudi  
**Étudiant :** ELAALGI Hatim  
**Sujet :** notebook *TP2Mesa_Simulation_MA.ipynb* — formation de l'opinion publique  
**Environnement :** Python 3.14, Mesa 3.5, NetworkX 3.7, dans un conteneur Docker (voir le [rapport du TP0](../TP0_installation/README.md))

---

## 1. Objectifs

- Implémenter avec **Mesa 3** un système multi-agents simulant la formation de l'opinion publique, décrit selon le protocole **ODD**.
- Observer l'émergence d'un consensus, d'une polarisation ou de groupes d'opinion.
- Répondre aux 8 questions d'analyse : dynamique du modèle, syntaxe de Mesa 3 et extensions (biais de confirmation, réseau social).

## 2. Le modèle (protocole ODD)

| Élément | Description |
|---|---|
| Entités | des citoyens (`CitizenAgent`), un par case d'une grille `MultiGrid` 10×10 torique |
| Variable d'état | l'opinion $o_i \in [0, 1]$, tirée au hasard à l'initialisation |
| Processus | à chaque tick, l'agent calcule la moyenne $\bar{o}$ de ses 8 voisins (voisinage de Moore) et met à jour son opinion : $o_i^{t+1} = o_i^t + \alpha(\bar{o} - o_i^t)$ |
| Ordonnancement | `self.agents.shuffle_do("step")` : tous les agents agissent une fois par tick, dans un ordre aléatoire |
| Observation | `DataCollector` : opinion moyenne et variance (niveau du modèle), opinion de chaque agent (niveau des agents) |
| Entrées | taille de la grille, α, nombre de ticks, graine aléatoire (42 pour toutes les expériences) |

## 3. Démarche

1. Exécution du modèle de l'enseignant (grille 10×10, α = 0.5, 50 ticks).
2. Extension du modèle pour répondre aux questions avec des **mesures** :
   - un indicateur supplémentaire, l'**écart max-min** des opinions ;
   - un seuil de tolérance **ε** optionnel (biais de confirmation) ;
   - une collecte de l'état initial et de l'état **après** chaque tick.
3. Une expérience par question : variation de α, de ε, de `torus` ; réseau Barabási-Albert avec `NetworkGrid` pour la question 8.

## 4. Résultats de la simulation de base

| Indicateur | tick 0 | tick 50 |
|---|---|---|
| Opinion moyenne | 0.480 | 0.479 |
| Variance | 0.086 | 6 × 10⁻⁸ |

La variance passe sous 10⁻⁴ au **tick 14** : toute la population converge vers une opinion commune, proche de la moyenne de départ.

![Moyenne et variance](figures/1_moyenne_variance.png)
![Trajectoires individuelles](figures/2_trajectoires.png)

## 5. Réponses aux questions

### Q1 — Impact de α sur la vitesse de convergence

| α | variance au tick 10 | tick où la variance passe sous 10⁻⁴ |
|---|---|---|
| 0.01 | 0.0708 | plus de 200 |
| 0.1 | 0.0144 | 87 |
| 0.5 | 0.0003 | 14 |
| 1.0 | 0.00001 | 7 |

α est la fraction de l'écart avec ses voisins que l'agent comble à chaque tick : il fixe la **vitesse** de convergence, pas son issue. Avec α proche de 0, les trajectoires restent presque plates et le consensus demande des centaines de ticks. Avec α = 1, chaque agent remplace son opinion par la moyenne de ses voisins, et tout se resserre en quelques ticks.

![Impact de alpha](figures/3_impact_alpha.png)

### Q2 — Pourquoi la polarisation est impossible
La règle s'écrit $o_i^{t+1} = (1-\alpha)\,o_i^t + \alpha\,\bar{o}$ : c'est une **moyenne pondérée**, qui reste toujours comprise entre la plus petite et la plus grande opinion existante. Chaque agent écoute en plus **tous** ses voisins, sans aucune force de rejet. L'écart entre les opinions extrêmes ne peut donc que diminuer : on mesure qu'il passe de **0.991 à 0.0009** en 50 ticks, sans aucune hausse d'un tick à l'autre.

### Q3 — L'émergence
Aucun agent ne connaît l'opinion globale ni ne cherche à atteindre un consensus : chacun ne regarde que ses 8 voisins. Pourtant, la variance tombe à 0 et les trajectoires se rejoignent en un seul faisceau. Le consensus est un comportement **global** qui n'est écrit dans aucune règle **individuelle** : c'est l'émergence au sens du protocole ODD.

### Q4 — Activation avec `shuffle_do("step")`
Dans Mesa 3, les agents s'enregistrent automatiquement dans `self.agents`, et `shuffle_do("step")` remplace l'ancien `RandomActivation`. L'ordre change à chaque tick : par exemple `[3, 68, 51, …]`, puis `[93, 13, 89, …]`. Comme la mise à jour est asynchrone, un agent qui joue tard voit les opinions déjà modifiées de ses voisins. Un ordre fixe avantagerait toujours les mêmes agents ; l'ordre aléatoire supprime ce biais.

### Q5 — `model_reporters` et `agent_reporters`
- `model_reporters` : une ligne par tick, soit **51 lignes** (moyenne, variance, écart max-min).
- `agent_reporters` : une ligne par agent et par tick, soit **5 100 lignes**, indexées par `(Step, AgentID)`.

La moyenne seule ne distingue pas un consensus à 0.5 de deux camps à 0 et à 1. La variance mesure la dispersion, mais pas sa forme. Seules les trajectoires individuelles montrent qui converge vers quoi : il faut donc les deux niveaux d'observation.

### Q6 — `torus=True` et les agents du bord
Avec `torus=True`, la grille est refermée sur elle-même : l'agent situé en (0, 0) a **8 voisins**, dont ceux de la colonne x = 9 et de la ligne y = 9. Avec `torus=False`, il n'en a que **3**. Le tore supprime les effets de bord : tous les agents ont le même poids dans la dynamique.

### Q7 — Biais de confirmation
On modifie `step()` pour ne garder que les voisins dont l'opinion est proche :
```python
neighbors = [n for n in neighbors if abs(n.opinion - self.opinion) < self.epsilon]
```
Résultats sur une grille 20×20, avec α = 0.5 et 1000 ticks :

| ε | groupes | grands groupes (au moins 20 agents) | plus grand groupe | agents isolés | phénomène |
|---|---|---|---|---|---|
| 1.0 | 1 | 1 | 100 % | 0 | consensus |
| 0.3 | 2 | 1 | 100 % | 1 | consensus, avec un extrémiste isolé |
| 0.15 | 29 | 2 | 70 % | 17 | **polarisation** |
| 0.05 | 254 | 0 | 3 % | 180 | **fragmentation** |

On retrouve le modèle de **confiance bornée** : plus la tolérance est faible, plus la société se divise en **chambres d'écho**, et les agents aux opinions extrêmes ne changent plus d'avis.

![Biais de confirmation](figures/4_biais_confirmation.png)

### Q8 — Réseau social et influenceurs
On utilise **`mesa.space.NetworkGrid`** avec un graphe **sans échelle** de Barabási-Albert (300 utilisateurs) : le degré médian vaut 3, mais le plus gros hub a 55 connexions. On rend 5 agents « têtus » (opinion fixée à 1, α = 0) :

| 5 agents têtus | opinion moyenne des autres : tick 0 → tick 10 → tick 30 |
|---|---|
| aucun | 0.493 → 0.482 → 0.482 |
| les 5 **hubs** (degrés 16 à 55) | 0.493 → 0.766 → **0.939** |
| 5 **périphériques** (degré 2) | 0.493 → 0.501 → 0.545 |

Avec le même nombre de personnes, c'est la **position** dans le réseau qui compte : les influenceurs entraînent presque toute la population, alors que les utilisateurs isolés la déplacent à peine.

![Réseau et influenceurs](figures/5_reseau_influenceurs.png)

## 6. Difficultés et corrections

| Problème | Correction |
|---|---|
| `for _, x, y in self.grid.coord_iter()` provoque une erreur avec Mesa 3.5, car `coord_iter()` renvoie `(contenu, (x, y))` | `for _, (x, y) in self.grid.coord_iter()` |
| le paramètre `seed=` de `mesa.Model` est déprécié au profit de `rng=` | `super().__init__(rng=seed)` |
| dans le modèle fourni, la collecte a lieu avant que les agents agissent, donc l'état final n'est jamais enregistré | dans le modèle étendu, collecte de l'état initial dans `__init__`, puis collecte après chaque tick |

## 7. Conclusion

- Une règle **locale et simple** produit un **consensus global** sans coordination centrale : c'est l'émergence. α n'en règle que la vitesse (7 ticks pour α = 1, plus de 200 pour α = 0.01).
- Ce consensus est **garanti mathématiquement** : une moyenne ne sort jamais de l'intervalle des opinions existantes.
- Une **tolérance limitée** (ε) suffit à faire apparaître la polarisation puis la fragmentation, et une **topologie réaliste** (graphe sans échelle) permet à quelques influenceurs de dominer l'opinion.
