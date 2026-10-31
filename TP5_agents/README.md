# Rapport — TP5 : IA agentique avec LangChain

**Module :** Système Distribué Agentique  
**Formation :** Master Intelligence Artificielle & Digital Computing (S3) — FST, Université Moulay Slimane  
**Année universitaire :** 2026–2027  
**Enseignant :** Lhoussaine Daoudi  
**Étudiant :** ELAALGI Hatim  
**Sujet :** notebook *AI_Agentic.ipynb* — « Agentic AI: Langchain »  
**Environnement :** Python 3.14 dans un conteneur Docker (voir le [rapport du TP0](../TP0_installation/README.md)), LangChain 1.x / LangGraph, API Groq, PostgreSQL dans Docker

---

## 1. Objectifs

Construire des **agents** avec l'API `create_agent` de LangChain, puis les contrôler. Un agent est un LLM qui décide lui-même d'appeler des outils, en boucle, jusqu'à pouvoir répondre. Le TP couvre :
- l'agent simple et la configuration du modèle ;
- le **choix dynamique du modèle** ;
- la **mémoire** (en RAM, puis persistante dans PostgreSQL) ;
- les **outils** : fonctions Python, recherche web, exécution de code Python ;
- le **prompt système dynamique**, la **sortie structurée** et le **middleware** personnalisé ;
- le **RAG utilisé comme outil** de l'agent ;
- les **garde-fous** : données personnelles (PII), validation humaine (*human-in-the-loop*), filtres avant et après l'agent.

## 2. Environnement et choix techniques

| Élément | Support de l'enseignant | Ma réalisation |
|---|---|---|
| LLM | OpenAI (`langchain-openai`) ou Ollama | Groq : `openai/gpt-oss-120b`, `openai/gpt-oss-20b`, `qwen/qwen3.8-27b` |
| Mémoire persistante | `PostgresSaver` | PostgreSQL dans un conteneur Docker (`agentic-postgres`), joint depuis le conteneur Jupyter par `host.docker.internal:5432` |
| Recherche web | DuckDuckGo (`ddgs`), Tavily | identique |
| Exécution de code | `PythonREPL` / `PythonREPLTool` (`langchain-experimental`) | identique |
| Embeddings du RAG | modèle OpenAI | FastEmbed local `paraphrase-multilingual-MiniLM-L12-v2` (Groq ne fournit pas d'embeddings) + FAISS |

Clés lues dans le fichier `.env` (non versionné) : `GROQ_API_KEY` et `TAVILY_API_KEY`.

## 3. Démarche et résultats

### 3.1 Agent simple, sans mémoire
Premier appel : « My first name is Lhoussaine and my last name is daoudi ». L'agent répond « Nice to meet you, Lhoussaine Daoudi! ». Deuxième appel : « i'm Lhoussaine what is my last name ». L'agent répond qu'il n'a **pas cette information**. Sans mémoire, chaque `invoke()` est indépendant : l'agent oublie la conversation.

### 3.2 Configuration du modèle et choix dynamique
- `ChatGroq(model="openai/gpt-oss-120b", temperature=0.1, max_tokens=1000, timeout=30)`. Avec `debug=True`, chaque étape du graphe de l'agent est affichée (`[values]`, `[updates]`).
- **Modèle dynamique :** un middleware `@wrap_model_call` choisit le modèle selon le contexte d'exécution. Le même message « Test 1 » produit :

| `context` | Modèle annoncé | Modèle réellement utilisé (métadonnées) | Tokens (prompt / réponse / dont raisonnement) |
|---|---|---|---|
| `{'env': 'test'}` | basic model | `openai/gpt-oss-20b` | 74 / 99 / 76 |
| `{'env': 'prod'}` | advanced model | `openai/gpt-oss-120b` | 74 / 76 / 47 |

Le routage fonctionne : on peut réserver le grand modèle (plus cher) à la production.

### 3.3 Mémoire
| Checkpointer | Échange | Résultat |
|---|---|---|
| `InMemorySaver`, `thread_id=1` | « My Name is Daoudi », puis « What is my name » | « Your name is Daoudi. » |
| `PostgresSaver` (PostgreSQL dans Docker) | « My Name is Daoudi » | réponse correcte ; `checkpointer.setup()` crée les tables et la conversation est enregistrée en base |

La mémoire repose sur deux éléments : un **checkpointer** qui sauvegarde l'état, et un **`thread_id`** qui identifie la conversation. Avec PostgreSQL, l'historique survit au redémarrage du kernel.

### 3.4 Outils
| Requête | Outil appelé | Réponse |
|---|---|---|
| « What is the weather in BeniMellal » | `get_weather("Beni Mellal")` | ensoleillé, 32 °C |
| « Quel est le job de Lhoussaine et le domaine de recherche » | `get_employee_info("Lhoussaine")` | « développeur » ; l'agent précise que le domaine de recherche **n'est pas** dans les informations, sans l'inventer |
| « What are news » (deux fois) | **aucun** | définition générale des actualités, tirée des connaissances du modèle |

Le modèle choisit un outil d'après sa **description** (*docstring*). « Search for news. » ne correspond pas clairement à la question « What are news », comprise comme une demande de définition : l'outil n'est pas appelé.

**Recherche web (DuckDuckGo).** Pour « Search for Agentic RAG tutorials », l'agent a lancé **7 recherches** reformulées (« Agentic RAG LangChain tutorial », `site:datacamp.com "Agentic RAG"`, etc.), puis a produit un tableau de 5 tutoriels avec leurs liens. Ce nombre d'appels s'explique par un défaut de l'outil : son `return` est placé dans la boucle, donc chaque recherche ne renvoie qu'**un seul** résultat, et une recherche a renvoyé `null` après une exception. L'agent a compensé ce défaut en multipliant les requêtes : c'est la boucle agentique en action, mais elle a un coût en appels.

**Recherche web (Tavily).** Le prompt système contient la date du jour. Pour « Quel temps fait-il aujourd'hui à BeniMellal », l'outil est appelé deux fois. La réponse est datée du 29 octobre 2026 et cite ses sources (timeanddate.com, WorldWeatherAI) : 17,8 °C avec du brouillard le matin, entre 20 et 27 °C dans l'après-midi.

### 3.5 Exécution de code Python (REPL)
| Demande | Ce que fait l'agent | Résultat |
|---|---|---|
| exécuter `a=5 ; b=9 ; print(...)` | appelle `repl_tool` avec le code | « la somme de 5 et 9 est 14 » |
| trier `liste1=[5,3,8]` et `liste2=(1,9,3]`, puis les additionner | corrige la faute de syntaxe `(1,9,3]`, trie, puis propose deux interprétations de « additionner » | `[3, 5, 8]` et `[1, 3, 9]` ; concaténation `[3, 5, 8, 1, 3, 9]` ; somme terme à terme `[4, 8, 17]` |
| racines exactes de $6x^2 + 11x - 6 = 0$ avec sympy ou numpy, résultat écrit dans `CodeReslt.txt` | sympy n'est pas installé (`ModuleNotFoundError`) : l'agent **s'adapte** et utilise `math` | $\Delta = 265$, racines $\frac{-11 \pm \sqrt{265}}{12} \approx 0{,}4399$ et $-2{,}2732$, écrites dans le fichier |

Le dernier cas montre une capacité clé des agents : lire l'erreur renvoyée par l'outil et changer de méthode. Il montre aussi le risque : `PythonREPLTool` exécute **n'importe quel code** généré par le modèle.

### 3.6 Prompt système dynamique
Le middleware `@dynamic_prompt` construit le prompt système selon le rôle de l'utilisateur, passé dans `context`. La même question, « Explain AI agent », reçoit deux réponses différentes :
- `expert` : une réponse technique et formelle (fonction d'agent $f: P \rightarrow A$, composants, tableaux) ;
- `beginner` : une explication simple, avec des exemples de la vie courante (assistant vocal, aspirateur robot).

### 3.7 Sortie structurée
Avec `response_format=ToolStrategy(ContactInfo)` (un modèle Pydantic à 3 champs) et `gpt-oss-20b`, le texte « Lhoussaine DAOUDI, lhoussaine.daoudi@usms.ma, (212)254430044 » est converti en objet Python. Les trois champs `name`, `email` et `phone` sont extraits correctement.

### 3.8 Middleware personnalisé (hooks)
La classe `HooksDemo(AgentMiddleware)` affiche les hooks dans l'ordre d'exécution : `before_agent` → `before_model` → `after_model` → `after_agent`. Elle mesure aussi la durée totale de l'agent : **20,7 s** pour « Tel me how many cities in morocco ». Ces points d'accroche servent à la journalisation, à la mesure et aux garde-fous.

### 3.9 RAG utilisé comme outil
8 phrases de présentation sont vectorisées (FastEmbed + FAISS). La recherche « Nom, prénom et affiliation » (k = 2) renvoie bien la phrase sur la FST de Béni Mellal et celle sur le nom. Le retriever devient ensuite un outil (`create_retriever_tool`, nommé `kb_search`) d'un agent. À la question « Nom et Prénom, Affiliation et diplômes », l'agent répond :
- nom et affiliation (FST de Béni Mellal) : **corrects** ;
- mais il développe le sigle USMS en « Université **Sidi Mohamed Ben Abdellah** » (USMS = Université Sultan Moulay Slimane) ;
- il **invente** un « diplôme d'ingénieur (4 ans) » en informatique, alors que le texte dit seulement « j'ai étudié à la FST d'Errachidia pendant 4 ans » ;
- il **omet** le doctorat d'État obtenu en 2025.

### 3.10 Garde-fous
| Garde-fou | Test | Résultat |
|---|---|---|
| `PIIMiddleware` : email (`redact`), carte bancaire (`mask`), clé API (`block`) | « My email is … and card is 45000-7389-4320-7 » | la réponse ne reproduit ni l'email ni le numéro de carte ; le modèle demande quelle action effectuer |
| `HumanInTheLoopMiddleware` sur `send_email` | « Send an email to … » | le modèle **n'appelle pas** l'outil : il demande d'abord l'objet et le corps du message. Sans appel d'outil, il n'y a pas d'interruption, d'où `KeyError: '__interrupt__'` |
| filtre `@before_agent` par mots interdits (`hack`, `exploit`, `malware`) | « How do I hack into a database? » | **bloqué avant tout appel au modèle** : « I cannot process requests containing inappropriate content » |
| juge de sécurité `@after_agent` (`gpt-oss-20b`) | « How do I make explosives? » | « I'm sorry, but I can't help with that. » |
| `bind_tools` avec `qwen/qwen3.8-27b` | « Météo à Marrakech » | aucun appel d'outil : réponse générale sur le climat de Marrakech |

## 4. Analyse

1. **Un agent = un LLM + des outils + une boucle.** L'agent choisit seul quand appeler un outil, corrige des entrées mal formées (`(1,9,3]`), contourne une erreur (sympy absent) ou relance une recherche insuffisante. La qualité dépend donc autant des **outils et de leurs descriptions** que du modèle : une description vague (« Search for news ») et l'outil n'est pas utilisé ; un outil défectueux, et l'agent multiplie les appels.
2. **La mémoire n'est pas dans le modèle.** Elle vient du checkpointer et du `thread_id`. Sans eux, l'agent oublie tout d'un appel à l'autre (section 3.1).
3. **Le middleware est le plan de contrôle de l'agent.** Le même mécanisme sert à choisir le modèle (coût), à adapter le prompt (public visé), à mesurer (hooks) et à protéger (garde-fous).
4. **Le RAG comme outil n'empêche pas les hallucinations.** Contrairement au TP4, le prompt de l'agent ne lui demande pas de se limiter au contexte ni de répondre « Je ne sais pas ». Le modèle complète donc avec ses propres connaissances, de façon fausse (USMS, diplôme d'ingénieur). Il faudrait reprendre la consigne du TP4 dans le `system_prompt`.
5. **Les garde-fous ont chacun leurs limites.**
   - Le filtre par mots-clés est rapide et déterministe, mais naïf : « hack » bloquerait aussi « hackathon ».
   - Le juge `after_agent` coûte un appel de modèle supplémentaire.
   - Le *human-in-the-loop* ne se déclenche que si le modèle **appelle** l'outil sensible. Pour le tester, il faut une demande complète (destinataire, objet, corps) et vérifier `"__interrupt__" in result` avant de lire la clé.
6. **`bind_tools` ne suffit pas.** Il permet seulement au modèle de **proposer** un appel d'outil, sans l'exécuter. C'est `create_agent` qui fournit la boucle exécution → observation → réponse.

## 5. Difficultés et anomalies relevées

| Point | Observation | Correction ou piste |
|---|---|---|
| Fournisseur LLM | pas de clé OpenAI | Groq via `ChatGroq` / `init_chat_model("groq:...")` |
| PostgreSQL | Jupyter tourne dans Docker : `localhost` désigne le conteneur, pas le PC | `host.docker.internal:5432`, et connexion gardée ouverte (sans `with`) pour les cellules suivantes |
| Embeddings | Groq n'a pas d'API d'embedding | FastEmbed local, multilingue |
| `sympy` absent de l'environnement | `ModuleNotFoundError` dans le REPL | l'agent est passé à `math` ; `uv add sympy` pour la version exacte |
| Ordre d'exécution | la cellule `print(resp['messages'][-1].content)` qui suit le polynôme a été exécutée après une autre cellule et affiche la réponse sur les listes | résultat du polynôme lu dans la trace `debug` ; ré-exécuter les cellules dans l'ordre |
| `web_search` | `return formatted_results` dans la boucle (1 seul résultat) et `(title]` au lieu de `{title}` | sortir le `return` de la boucle, corriger la f-string |
| `get_weather` | `"Weather in {location): ..."` n'est pas une f-string | `f"Weather in {location}: ..."` |
| prompt `beginner` | `f"(base_prompt) Explain..."` : le prompt envoyé est littéralement « (base_prompt) Explain concepts simply… » | `f"{base_prompt} Explain..."` |
| détecteur de clé API | la regex `[a-zA—Z0-9]` contient un tiret long (—) au lieu de `-` : les majuscules B à Y ne sont pas reconnues | `[a-zA-Z0-9]` |
| retriever du RAG | `as_retriever(kwargs={'k': 5})` : ce n'est pas le bon paramètre, le retriever garde sa valeur par défaut | `as_retriever(search_kwargs={'k': 5})` (même erreur qu'au TP4) |
| outil `search_tool` (dernière section) | `tavily_searc_tool` (faute de frappe) et `{"query"}` (un ensemble) : l'outil échouerait s'il était appelé | `tavily_search_tool.invoke({"query": query})` |
| middleware `handle_tool_errors` | défini mais jamais déclenché dans le notebook | à tester avec un outil qui lève une exception |

## 6. Conclusion

Ce TP passe du LLM qui répond au **LLM qui agit**. Avec `create_agent`, un modèle choisit et enchaîne des outils (fonctions, recherche web, exécution de code, base de connaissances), garde une mémoire via un checkpointer, et se laisse piloter par des middlewares : choix du modèle, prompt adapté, hooks, garde-fous. Les expériences montrent la force de la boucle agentique : l'agent se corrige et contourne les erreurs. Elles en montrent aussi les risques : hallucinations quand le prompt ne borne pas les réponses, coût des appels répétés, exécution de code arbitraire. D'où l'importance des garde-fous, à condition de les tester correctement : un *human-in-the-loop* ne protège que si l'outil sensible est réellement appelé.
