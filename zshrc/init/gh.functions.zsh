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
    labels=${4:-""}
    repo="https://github.com/"${2:-$MY_SERVICE}
    github_token=${3:-$GITHUB_TOKEN}
    # runner_group=${4:-"default"}


    docker run -d --restart always --name $name \
        -e REPO_URL=$repo\
        -e RUNNER_NAME=$name \
        -e ACCESS_TOKEN=$github_token \
        -e LABELS=$labels \
        -v /var/run/docker.sock:/var/run/docker.sock \
        myoung34/github-runner:latest
}

function gh_release(){              #usage: gh_release {version vx.y} {repo x/y}
    service=${2:-${MY_SERVICE}}
    version=${1:-v$(gh_increment_version $service)}
    echo creating release for $service version $version
    gh release create --repo $service $version --generate-notes --title $version
}

function gh_increment_version(){    #gives you the next incremental version of your github project
    service=${1:-${MY_SERVICE}}
    current_version=$(gh release view --json tagName --jq '.tagName' --repo $service | head)
    current_version=${current_version#?} #remove the v from the start of the tag
    new_version=$(echo $current_version | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{if(length($NF+1)>length($NF))$(NF-1)++; $NF=sprintf("%0*d", length($NF), ($NF+1)%(10^length($NF))); print}')
    echo $new_version
}

function gh_issue(){               #usage: gh_issue {title} {body} {repo x/y}
    gh issue create --title "$*" --body ""
}
alias todo="gh_issue"

function clone(){                   #usage: clone {repo x/y}
    repo = ${1:-$MY_SERVICE}
    folder = ${2:-$(echo $repo | cut -d'/' -f2)}
    gh repo clone $1 
}

function gh_clear_notifications(){
    gh api /notifications \
    | jq -r '.[] | select(.reason == "review_requested") | select(.repository.owner.login == "qlik-trial") | .id' \
    | xargs -P0 -I{} gh api /notifications/threads/{} -X PATCH -f "read=true"
}

function gh_notifications(){
    gh_clear_notifications
    gh api /notifications | jq '. | length' | grep -v -w 0 && \
    open "https://github.com/notifications?query=is%3Aunread" || echo "No notifications"
}