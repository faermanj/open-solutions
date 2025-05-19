#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_DIR=$(dirname $DIR)

# Define variables
export NAMESPACE="openshift-gitops-operator"
export CONFIG_FOLDER="$SRC_DIR/config/gitops"
export REPO_URL_HTTP="https://github.com/faermanj/go-practice"

# Check cluster is up 
oc cluster-info

oc create ns $NAMESPACE
oc apply -f $CONFIG_FOLDER/gitops-operator-group.yaml

echo "OpenShift GitOps installation and configuration complete."