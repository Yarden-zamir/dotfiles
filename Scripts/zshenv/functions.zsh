function sde-cluster-pods() {
    kubectl get pods
}
function sde-cluster-pull() {
    trigram=${1:-${USERNAME:$USER}}
    scp rddev@${trigram}.pte.qlikdev.com:/home/rddev/.kube/config ~/kubeconfigs/${trigram}-kubeconfig
}

function sde-cluster-set() {
    trigram=${1:-${USERNAME:$USER}}
    export CLUSTER_TRIGRAM=$trigram
    export KUBECONFIG=~/kubeconfigs/${trigram}-kubeconfig
}

function sde-cluster-connect() {
    trigram=${1:-${USERNAME:$USER}}
    sde-cluster-invalidate ${trigram}
    sde-cluster-pull ${trigram}
    sde-cluster-set ${trigram}
}

function sde-cluster-invalidate() {
    trigram=${1:-${USERNAME:$USER}}
    sed -i '' "/^${trigram}/d" ~/.ssh/known_hosts
}

function sde-extend(){
    trigram=${1:-${USERNAME:$USER}}
    days=${2:-365}
    echo extending sde of ${trigram} for ${days} days
    gh workflow run developer-extend-sde-lease.yaml -f sdename=$trigram -f extenddays=$days --repo qlik-trial/qcs-environments
}

function sde-status(){
    trigram=${1:-${USERNAME:$USER}}
    slack=${2:-${SLACK_HANDLE}}
    echo sending current status of sdes for $trigram to slack user $slack
    gh workflow run developer-list-my-sdes.yaml -f sde_name=$trigram -f slack_handle=$slack --repo qlik-trial/qcs-environments
}

function sde-system-test(){
    gh workflow run "Personal system test" --repo qlik-trial/data-app-design-systest -F host="yarden.eu.kcw.pte.qlikdev.com" -f token_key="KCW_TOKEN" -f space="automation" -f SQL_SERVER="SQLServ.3" -f SNOWFLAKE="Snowflake" -f BIG_QUERY_GCS="Cloud_Storage" -f BIG_QUERY="BigQuery"
    #  -f AZURE_SYNAPSE="Azure_Synapse_Analytics" -f AZURE_DATA_LAKE_STORAGE="Azure_Data_Lake_Storage"
    gh workflow view personalSystemTest.yaml --web --repo qlik-trial/data-app-design-systest
}

function gh-release(){              #usage: gh_release {version vx.y} {repo x/y}
    service=${2:-${MY_SERVICE}}
    version=${1:-v$(gh_increment_version $service)}
    echo creating release for $service version $version
    gh release create --repo $service $version --generate-notes --title $version
}

function gh-increment-version(){    #gives you the next incremental version of your github project
    service=${1:-${MY_SERVICE}}
    current_version=$(gh release view --json tagName --jq '.tagName' --repo $service | head)
    current_version=${current_version#?} #removed the v from the start of the tag
    new_version=$(echo $current_version | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{if(length($NF+1)>length($NF))$(NF-1)++; $NF=sprintf("%0*d", length($NF), ($NF+1)%(10^length($NF))); print}')
    echo $new_version
}

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

function docker-stop-all(){
	docker stop $(docker ps -q)
}

function create-nav-shortcuts() {   # creates shortcuts for all directories in $1 using prefix $2
    nav_base=$1
    nav_simbol=${2:-@}
    cd $nav_base
    alias $nav_simbol$(basename $nav_base)="cd $nav_base"
    for dir in *; do if [[ -d $dir ]]; then
        alias $nav_simbol$dir="cd $nav_base/$dir;"
    fi; done
}