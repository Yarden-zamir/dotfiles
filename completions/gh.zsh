_gh_issue_list() {
    local -a issues
    # Fetch issues using gh CLI and format them with jq
    issues=("${(@f)$(gh issue list --json number,title --jq '.[] | "\(.number) \(.title)"' | sed 's/"/\\"/g')}")
    # Use compadd with -Q to avoid re-splitting the input
    compadd -Q -a issues
}
compdef _gh_issue_list complete
