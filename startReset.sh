#!/bin/bash

# Tentative de vérification si Docker est en cours d'exécution
if ! docker info > /dev/null 2>&1; then
  echo "Docker n'est pas en cours d'exécution. Tentative de démarrage de Docker Desktop..."
  # Stocker le chemin d'exécution actuel
  current_dir=$(pwd)
  echo "Chemin d'exécution actuel : $current_dir"
  
  # déplacement vers le répertoire de Docker Desktop
  echo "Changement de répertoire de travail à : $(pwd)"
  cd "C:\Program Files\Docker\Docker"

  # Démarrage de Docker Desktop
  echo "Démarrage de Docker Desktop..."
  "./Docker Desktop.exe"

  # Revenir au dossier original
  cd "$current_dir"
  echo "Retour au chemin d'exécution actuel : $(pwd)"

  # Attendre un moment pour que Docker Desktop démarre
  sleep 15
else
  echo "Docker est déjà en cours d'exécution."
fi

#fermeture des conteneurs Docker
docker-compose down -v

# Suppression explicite du volume mariadb-data
docker volume rm mariadb-data

# Vérifier si le réseau existe
if ! docker network ls --format "{{.Name}}" | grep -w "^ubo-network$"; then
  # Créer le réseau si ce n'est pas le cas
  docker network create --driver bridge ubo-network
else
  echo "Le réseau nomreseau existe déjà."
fi

# Lancez les services définis dans votre docker-compose.yml
echo "Démarrage des conteneurs Docker..."
docker-compose build

docker-compose up&

echo "Les conteneurs Docker ont été démarrés."
# Affichez un lien pour accéder au client web
echo "Accédez au client web à l'adresse suivante : http://localhost:8080"

sleep 50
