# 1. Image de base : on utilise une version stable et légère
FROM python:3.12-slim

# 2. Définit le dossier de travail à l'intérieur du conteneur
WORKDIR /app

# 3. Empêche Python de créer des fichiers .pyc (gain de place)
ENV PYTHONDONTWRITEBYTECODE 1
# 4. Affiche les logs en temps réel sans mise en tampon
ENV PYTHONUNBUFFERED 1

# 5. Copie le fichier des dépendances
COPY requirements.txt .

# 6. Installe les dépendances
RUN pip install --no-cache-dir -r requirements.txt

# 7. Copie tout le reste du code du projet
COPY . .

# 8. Commande pour démarrer l'API (Uvicorn est le serveur pour FastAPI)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]