# Vérifier si le conteneur existe et le supprimer s'il existe
docker ps -a | grep mongo && docker rm -f mongo

docker build -t mongodb .
docker run -d --name mongo --network ubo-network -p 27017:27017 mongodb