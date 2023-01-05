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
    current_version=${current_version#?} #removed the v from the start of the tag
    new_version=$(echo $current_version | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{if(length($NF+1)>length($NF))$(NF-1)++; $NF=sprintf("%0*d", length($NF), ($NF+1)%(10^length($NF))); print}')
    echo $new_version
}

function gh_issue(){               #usage: gh_issue {title} {body} {repo x/y}
    gh issue create --title "$*" --body ""
}
alias todo="gh_issue"