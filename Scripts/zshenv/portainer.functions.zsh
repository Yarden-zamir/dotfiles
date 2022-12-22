function portainer-start(){
    container=${1:-${PORTAINER_DEFAULT_CONTAINER}}
    token=$PORTAINER_TOKEN
    curl -X POST --location "https://qdi-portainer.qliktech.com/api/endpoints/4/docker/containers/$container/start" \
    -H "X-API-Key: $token"
}

function portainer-stop(){
    container=${1:-${PORTAINER_DEFAULT_CONTAINER}}
    token=$PORTAINER_TOKEN
    curl -X POST --location "https://qdi-portainer.qliktech.com/api/endpoints/4/docker/containers/$container/stop" \
    -H "X-API-Key: $token"
}