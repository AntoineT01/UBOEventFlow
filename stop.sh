#!/bin/bash

# Naviguez au répertoire contenant votre fichier docker-compose.yml
cd /chemin/vers/votre/projet

# Arrêtez et supprimez les conteneurs, les réseaux, les volumes et les images créés par `up`.
echo "Arrêt des conteneurs Docker..."
docker-compose down

echo "Les conteneurs Docker ont été arrêtés et supprimés."
