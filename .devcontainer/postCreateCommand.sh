#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPO_DIR=$(dirname $DIR)

echo "Executing postCreateCommand"
devbox install
source $REPO_DIR/.devcontainer/scripts/ocp-clients-get.sh

echo "Version checks"
oc version
openshift-install version

echo "postCreateCommand finished"