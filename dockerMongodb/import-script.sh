# SI la BDD ne se lance pas correctement, il faut modifiier le 
# Select end of line sequence to use: LF (Unix)

#!/bin/bash
# Démarrer MongoDB en arrière-plan
mongod --fork --logpath /var/log/mongodb.log --bind_ip_all

# Attendre que MongoDB démarre
echo "Attente du démarrage de MongoDB..."
while ! nc -z localhost 27017; do
  sleep 1
done
echo "MongoDB a démarré"

# Importer les données JSON dans MongoDB
mongoimport --uri "mongodb://localhost:27017/commentaires" --collection commentaires --file /usr/src/configs/mongodb_file.json --jsonArray

# Maintenant que l'importation est terminée, nous ne voulons pas terminer le script
# immédiatement car cela arrêterait le conteneur. On laisse donc MongoDB tourner en foreground.
# Ceci est un hack pour empêcher le script de terminer et le conteneur de s'arrêter.
# Notez que mongod ne doit pas être lancé une seconde fois en foreground ici, car il tourne déjà.
while true; do
  sleep 1
done
