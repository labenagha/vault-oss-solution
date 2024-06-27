#!/bin/bash
exec > >(sudo tee -a /var/log/ghrunner_install.log) 2>&1
set -x
set -e

USER="ubuntu"
REPO_NAME="hcp-vault-oss"
GITHUB_OWNER="labenagha"
RUNNER_DIR="/actions-runner"
RUNNER_URL="${RUNNER_URL}"
RUNNER_SHA="${RUNNER_SHA}"
RUNNER_TAR="${RUNNER_TAR}"
GITHUB_ACCESS_TOKEN="${GITHUB_ACCESS_TOKEN}"

function install_dependecies() {
    sudo apt -y update
    sudo apt -y install jq
}
install_dependecies

mkdir -p "$RUNNER_DIR"

function package_get() {
    cd "$RUNNER_DIR"
    curl -o actions-runner-linux-x64-2.317.0.tar.gz -L "${RUNNER_URL}"
    echo "${RUNNER_SHA}  actions-runner-linux-x64-2.317.0.tar.gz" | shasum -a 256 -c
    tar xzf "${RUNNER_TAR}"
}
package_get

function response_json() {
    curl -L \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GITHUB_ACCESS_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/$GITHUB_OWNER/$REPO_NAME/actions/runners/registration-token > response.json 

    sudo chown $USER:$USER response.json
    RUNNER_TOKEN=$(jq -r '.token' response.json)

    echo "RUNNER_TOKEN: $RUNNER_TOKEN"
    sudo chown -R $USER:$USER "$RUNNER_DIR"
}
response_json

sudo -u $USER bash <<EOF
cd "$RUNNER_DIR"
    ./config.sh --url https://github.com/$GITHUB_OWNER/hcp-vault-oss --token $RUNNER_TOKEN <<EOL
    Default
    gh-runner-01
    self-hosted,Linux,X64,gh-runner-01
    _work
    EOL
EOF

function execute() {
    ./run.sh &
    sudo chown -R $USER:$USER "$RUNNER_DIR"
    ./svc.sh install && ./svc.sh start
}
execute
