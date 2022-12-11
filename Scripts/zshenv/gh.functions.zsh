function gh_remove_runner(){
    repo=${1:-$MY_SERVICE}
    id=${2:-$GITHUB_RUNNER_ID}
    # GitHub CLI api
    # https://cli.github.com/manual/gh_api

    gh api \
    --method DELETE \
    -H "Accept: application/vnd.github+json" \
    /repos/$repo/actions/runners/$id
}

function gh_add_runner(){
    name=${1:-$GITHUB_RUNNER_NAME}
    echo $name
    labels=${5:-""}
    repo="https://github.com/"${2:-$MY_SERVICE}
    github_token=${3:-$GITHUB_TOKEN}
    runner_group=${4:-"default"}


    docker run -d --restart always --name $name \
        -e REPO_URL=$repo\
        -e RUNNER_NAME=$name \
        -e ACCESS_TOKEN=$github_token \
        -e RUNNER_WORKDIR="/tmp/$name-$(basename $repo)" \
        -e RUNNER_GROUP=$runner_group \
        -e LABELS=$labels \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /tmp/github-runner-your-repo:/tmp/github-runner-data-app-design-systest \
        myoung34/github-runner:latest
}