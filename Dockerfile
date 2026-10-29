# Version conteneurisée du "Guide Complet : Python, uv, VS Code & Jupyter Notebook" (TP0).
# Le .venv demandé par le guide vit dans l'image au lieu d'être sur la machine.
FROM ghcr.io/astral-sh/uv:bookworm-slim

# uv télécharge et gère lui-même Python, comme dans le guide
ENV UV_PYTHON_INSTALL_DIR=/opt/python \
    UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1

WORKDIR /app

# Étapes 2 et 4 du guide : fichiers du projet (uv init + uv add) -> uv venv -> dépendances verrouillées
COPY pyproject.toml uv.lock ./
RUN uv venv && uv sync --locked --no-install-project

# Étape 3 du guide : « activer » le venv pour toutes les commandes du conteneur
ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH"

# Étape cachée du guide : enregistrer le kernel sous le même nom
RUN python -m ipykernel install --sys-prefix --name=python_uv_workspace --display-name "Python (uv-env)"

# Les notebooks sont montés à l'exécution (voir compose.yaml) : la même image sert pour tous les TP
WORKDIR /app/work
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
