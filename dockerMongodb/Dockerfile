# Utiliser l'image officielle MongoDB comme image parent
FROM mongo:latest

# Installer netcat
RUN apt-get update && apt-get install -y netcat

# Définir le répertoire de travail dans le conteneur
WORKDIR /usr/src/configs

# Copier le fichier JSON dans le conteneur
COPY mongodb_file.json .

EXPOSE 27017

# Utiliser un script shell comme point d'entrée pour importer le fichier JSON
COPY import-script.sh .
RUN chmod +x import-script.sh

# Exécuter le script shell au démarrage du conteneur
ENTRYPOINT ["sh", "./import-script.sh"]
