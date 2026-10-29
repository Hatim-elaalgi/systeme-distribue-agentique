# TP1 — Rappels Python (partie 1) : résultats

Notebook : [TP1python_partie1.ipynb](TP1python_partie1.ipynb), exécuté dans VS Code avec le kernel **Python (uv-env)** du conteneur Docker (TP0). Les exercices utilisent `input()` : les résultats ci-dessous correspondent à mes saisies de test.

| Exercice | Notion travaillée | Saisie de test | Résultat obtenu |
|---|---|---|---|
| 1. Système de notation pondérée | conversions `str` / `float` / `int` | identifiant `CNE123456`, deux notes et deux coefficients | « Pour l'étudiant CNE123456, la moyenne finale du module est de 16.0 / 20. » |
| 2. Analyse d'une équation $ax^2+bx+c=0$ | tests imbriqués, puis un second bloc conditionnel séparé | coefficients avec $\Delta = 25$ | « Δ = 25.0 — L'équation admet deux solutions réelles distinctes. » |
| 3. Contrôle de saisie | boucle `while` (validation), puis boucle `for` + `range()` | `5` (saisie acceptée) | « Saisie acceptée ! Voici les nombres de 0 à 5 : » puis 0, 1, 2, 3, 4, 5 |
| 4. Traitement des notes | paramètre par défaut, immuabilité, `map()`, `zip()` | `x = 10`, `notes = [12.0, 15.5]` | `ajouter_bonus(x)` = 12 et **x reste 10** ; notes avec bonus `[14.0, 17.5]` ; Ali : 14.0, Sara : 17.5 |
| 5. Saisie ordonnée et médiane | listes, `while` pour forcer l'ordre croissant | 5 notes : 10, 12, 15, 18, 20 | nombre de notes impair, **médiane = 15.0** |
| 6. Configuration multi-agents | dictionnaire → liste → tuple | `config_ia` de l'énoncé | température passée à **0.5** ; extraction de **`Calculatrice`** avec `config_ia["agent_recherche"]["outils"][1][0]` |

## Points à retenir
- `input()` renvoie toujours une chaîne : on convertit tout de suite (`float()`, `int()`) avant de calculer, puis on reconvertit avec `str()` pour concaténer.
- Exercice 4 : `x` vaut toujours 10 après l'appel, car un `int` est **immuable**. La fonction crée un nouvel objet local au lieu de modifier `x`.
- Exercice 3 : la validation teste d'abord si la saisie est un nombre, puis si c'est un entier, puis s'il est impair, et affiche un message d'erreur différent dans chaque cas.
- Exercice 5 : la liste est triée dès la saisie, donc la médiane se lit directement à l'indice `n // 2` (n impair), ou se calcule comme la moyenne des deux valeurs centrales (n pair).
