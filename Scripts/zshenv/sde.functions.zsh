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

function sde-refresh-argo(){
    trigram=${1:-${USERNAME:$USER}}
    echo refreshing argocd applications for $trigram
    curl --silent "https://argocd.$trigram.pte.qlikdev.com/api/v1/applications?fields=%2Citems.spec" \
    | json_pp | grep '"path" : "qcs/sde/' | cut -c 34- | rev | cut -c 3- | rev | xargs -P 100 -I % -L1 \
    curl --silent "https://argocd.$trigram.pte.qlikdev.com/api/v1/applications/%?sync=normal&appNamespace=argocd" > /dev/null && \
    echo done refreshing argocd applications for $trigram
}