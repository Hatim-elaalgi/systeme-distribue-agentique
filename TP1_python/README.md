# Rapport — TP1 : Rappels Python (partie 1)

**Module :** Système Distribué Agentique  
**Formation :** Master Intelligence Artificielle & Digital Computing (S3) — FST, Université Moulay Slimane  
**Année universitaire :** 2026–2027  
**Enseignant :** Lhoussaine Daoudi  
**Étudiant :** ELAALGI Hatim  
**Sujet :** notebook *TP1python_partie1.ipynb*  
**Environnement :** Python 3.14 et uv dans un conteneur Docker (voir le [rapport du TP0](../TP0_installation/README.md))

---

## 1. Objectifs

Revoir les bases de Python utiles à la programmation d'agents :
- les **conversions de types** (`int`, `float`, `str`) ;
- les **structures conditionnelles** (`if`, `elif`, `else`, tests imbriqués) ;
- les **boucles** `for` (avec `range()`) et `while` ;
- les **fonctions** (paramètres par défaut, immuabilité, `map()`, `zip()`) ;
- les **listes** ;
- les **dictionnaires et tuples** pour structurer la configuration d'un système multi-agents.

## 2. Démarche

Le notebook [TP1python_partie1.ipynb](TP1python_partie1.ipynb) contient, pour chaque notion, le rappel de cours de l'enseignant suivi de ma solution. Les exercices lisent des saisies au clavier avec `input()`, ce qu'une exécution automatique ne permet pas : le notebook a donc été exécuté de manière interactive dans VS Code, avec le kernel du conteneur. Les résultats présentés ci-dessous correspondent à mes saisies de test.

## 3. Exercices réalisés et résultats

### 3.1 Système de notation pondérée (conversions)
`input()` renvoie toujours une chaîne : les notes sont converties en `float` et les coefficients en `int` dès la saisie. Le résultat est reconverti avec `str()` pour construire la phrase.

```python
moyenne = (note_projet * coeff_projet + note_ecrit * coeff_ecrit) / (coeff_projet + coeff_ecrit)
print("Pour l'étudiant " + identifiant + ", la moyenne finale du module est de " + str(round(moyenne, 2)) + " / 20.")
```
**Résultat :** « Pour l'étudiant CNE123456, la moyenne finale du module est de 16.0 / 20. »

### 3.2 Analyse d'une équation du second degré (conditions)
L'énoncé impose deux blocs distincts. Le premier bloc teste $a = 0$, avec un test imbriqué sur $b$, et fixe le booléen `est_second_degre`. Le second bloc, placé **après** le premier, ne s'exécute que si ce booléen est vrai : il calcule $\Delta = b^2 - 4ac$ et en déduit le nombre de solutions réelles.

**Résultat** (coefficients de test donnant $\Delta = 25$) : « Δ = 25.0 — L'équation admet deux solutions réelles distinctes. »

### 3.3 Contrôle de saisie et boucle d'affichage (`while` et `for`)
La boucle `while not valide` redemande la saisie tant qu'elle n'est pas un entier impair, avec un message d'erreur différent selon le cas : texte non numérique, nombre décimal ou nombre pair. Une boucle `for i in range(0, nombre + 1)` affiche ensuite les entiers de 0 jusqu'au nombre saisi ; le `+ 1` est nécessaire car la borne de fin de `range()` est exclue.

**Résultat** (saisie acceptée : 5) : « Saisie acceptée ! Voici les nombres de 0 à 5 : » puis 0, 1, 2, 3, 4, 5.

### 3.4 Traitement des notes (fonctions)
```python
def ajouter_bonus(note, bonus=2):
    note = note + bonus  # crée un nouvel objet local, x n'est pas modifié
    return note
```
| Test | Résultat |
|---|---|
| `x = 10`, puis `ajouter_bonus(x)` | renvoie 12, et **x vaut toujours 10** |
| `list(map(ajouter_bonus, [12.0, 15.5]))` | `[14.0, 17.5]` |
| `zip(["Ali", "Sara"], notes_bonus)` | Ali : 14.0, Sara : 17.5 |

`x` n'est pas modifié car un `int` est **immuable** : la fonction travaille sur un nouvel objet local.

### 3.5 Saisie ordonnée et calcul de la médiane (listes)
Une boucle `for` saisit les notes une par une, et une boucle `while` interne force la ressaisie tant qu'une note est inférieure à la précédente (`notes[-1]`). La liste est donc déjà triée, et la médiane se lit directement : `notes[n // 2]` si n est impair, sinon la moyenne des deux valeurs centrales.

**Résultat** (notes saisies : 10, 12, 15, 18, 20) : nombre de notes impair, **médiane = 15.0**.

### 3.6 Configuration d'un système multi-agents (dictionnaires, listes, tuples)
```python
config_ia = {}
config_ia["agent_recherche"] = {
    "modele": "gpt-4",
    "temperature": 0.2,
    "outils": [("WebSearch", "v2.1"), ("Calculatrice", "v1.0")],
}
config_ia["agent_recherche"]["temperature"] = 0.5          # modification sans tout redéclarer
print(config_ia["agent_recherche"]["outils"][1][0])        # dictionnaire -> liste -> tuple
```
**Résultat :** « Température : 0.5 », puis « Calculatrice ».

## 4. Synthèse des résultats

| Exercice | Notion | Résultat |
|---|---|---|
| Notation pondérée | conversions | moyenne de 16.0 / 20 |
| Équation du second degré | conditions imbriquées et successives | Δ = 25, deux solutions réelles |
| Contrôle de saisie | `while`, `for`, `range()` | 0 à 5 affichés après validation |
| Traitement des notes | paramètre par défaut, immuabilité, `map`, `zip` | x reste 10 ; `[14.0, 17.5]` |
| Médiane | listes | médiane = 15.0 |
| Configuration multi-agents | dict → liste → tuple | `Calculatrice` |

## 5. Difficultés et remarques
- Les cellules qui utilisent `input()` bloquent une exécution automatique (`nbconvert`). Elles doivent être exécutées dans VS Code, où l'utilisateur répond aux saisies.
- La validation de l'exercice 3 traite aussi un cas que l'énoncé ne cite pas : une saisie qui n'est pas un nombre du tout. `float()` lève alors une `ValueError`, interceptée par `try / except`.
- Lors de la mise au propre du notebook, une copie de l'exercice 3 placée avant son énoncé a été remplacée par l'exemple de boucle `while` du rappel de cours.

## 6. Conclusion
Les six exercices sont résolus et testés. Ils couvrent les bases réutilisées dans les TP suivants : les boucles et les fonctions pour les simulations Mesa (TP2), et les dictionnaires et listes de messages pour les appels aux LLM (TP3 et TP4). Le dernier exercice montre en particulier qu'un dictionnaire imbriqué est une structure naturelle pour décrire la configuration d'un agent : modèle, température et outils.
