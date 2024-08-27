#!/bin/bash

# shellcheck disable=SC2034

ROOT_DIR="$(dirname "${BASH_SOURCE[0]}")"

[[ -f .env ]] &&  source .env

source "$ROOT_DIR/src/pr_format.sh"
source "$ROOT_DIR/src/generic.sh"

[ -f "$ROOT_DIR/src/dev/debug.sh" ] && source "$ROOT_DIR/src/dev/debug.sh"

# Template Configuration
APP_ROOT_DIR=$(git rev-parse --show-toplevel) || error_and_exit "This directory is not a git repository"
PR_TEMPLATE="$APP_ROOT_DIR/.github/PULL_REQUEST_TEMPLATE.md"
[ -z "$PR_TEMPLATE" ] && error_and_exit "PR template file $PR_TEMPLATE not found."

BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || error_and_exit "Failed to get the current branch name."
GH_CLI_INSTALLATION_URL="https://cli.github.com/"
BASE_BRANCH=${BASE_BRANCH:-"main"}
ASSIGNEE=${ASSIGNEE:-"@me"}

LABEL=${LABEL:-$(find_default_label "$BRANCH_NAME")}
TICKET_KEY=$(get_ticket_key "$BRANCH_NAME")
TICKET_NUMBER=$(get_ticket_number "$BRANCH_NAME")
PR_TITLE=$(format_title "$BRANCH_NAME")
PR_BODY=$(format_pr_body "$TICKET_KEY" "$TICKET_NUMBER" "$PR_TEMPLATE")

validate_gh_cli_is_installed
validate_the_branch_has_commits
validate_base_branch_exists

# Push the current branch
if ! git push -u origin "$BRANCH_NAME"; then
    error_and_exit "Failed to push the current branch to the remote repository. Please check your git remote settings."
fi

# Create the PR with the specified options
if ! gh pr create --title "$PR_TITLE" \
                   --base "$BASE_BRANCH" \
                   --head "$BRANCH_NAME" \
                   --assignee "$ASSIGNEE" \
                   --label "$LABEL" \
                   --body "$PR_BODY"; then
    error_and_exit "Failed to create the pull request. Ensure you have the correct permissions and the repository is properly configured."
fi

echo "Pull request created successfully."
