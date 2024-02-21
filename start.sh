#!/bin/bash

# Naviguez au répertoire contenant votre fichier docker-compose.yml
cd /chemin/vers/votre/projet

# Lancez les services définis dans votre docker-compose.yml
echo "Démarrage des conteneurs Docker..."
docker-compose up -d

echo "Les conteneurs Docker ont été démarrés."

# Affichez un lien pour accéder au client web
echo "Accédez au client web à l'adresse suivante : http://localhost:8080"
