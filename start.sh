#!/bin/bash

# Tentative de vérification si Docker est en cours d'exécution
if ! docker info > /dev/null 2>&1; then
  echo "Docker n'est pas en cours d'exécution. Tentative de démarrage de Docker Desktop..."
  # Remplacez par le chemin d'accès à Docker Desktop sur votre système si nécessaire
  "/mnt/c/Program Files/Docker/Docker/Docker Desktop.exe" &
  # Attendre un moment pour que Docker Desktop démarre
  # Note : Ceci est une attente arbitraire ; ajustez selon les besoins de votre système
  sleep 30
else
  echo "Docker est déjà en cours d'exécution."
fi

# Naviguez au répertoire contenant votre fichier docker-compose.yml
cd /chemin/vers/votre/projet

# Lancez les services définis dans votre docker-compose.yml
echo "Démarrage des conteneurs Docker..."
docker-compose up -d

echo "Les conteneurs Docker ont été démarrés."

# Affichez un lien pour accéder au client web
echo "Accédez au client web à l'adresse suivante : http://localhost:8080"
