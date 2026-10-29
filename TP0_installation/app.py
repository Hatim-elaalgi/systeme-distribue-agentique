import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# 1. Test rapide des bibliothèques installées
data = {'Catégories': ['A', 'B', 'C', 'D'], 'Valeurs': [12, 31, 19, 26]}
df = pd.DataFrame(data)
print(df)

# 2. Génération d'un graphique de validation
sns.set_theme(style="darkgrid")
sns.barplot(x='Catégories', y='Valeurs', data=df)
plt.title("Validation de l'environnement uv")
# Dans le conteneur il n'y a pas d'écran : plt.show() n'affiche rien, on enregistre donc l'image
plt.savefig("TP0_installation/validation_uv.png", dpi=100)
plt.show()
