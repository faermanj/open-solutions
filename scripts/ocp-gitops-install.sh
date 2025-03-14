#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_DIR=$(dirname $DIR)

# Define variables
NAMESPACE="openshift-gitops"
CONFIG_FOLDER="SRC_DIR/gitops/"
REPO_URL_HTTP="https://github.com/faermanj/go-practice"

# Create the namespace for OpenShift GitOps
echo "Creating namespace $NAMESPACE..."
oc create namespace $NAMESPACE

# Install the OpenShift GitOps operator
echo "Installing OpenShift GitOps operator..."
oc apply -f https://raw.githubusercontent.com/redhat-developer/gitops-operator/release-latest/deploy/openshift-gitops/subscription.yaml -n $NAMESPACE

# Wait for the operator to be ready
echo "Waiting for the OpenShift GitOps operator to be ready..."
oc wait --for=condition=available --timeout=600s deployment/openshift-gitops-operator -n $NAMESPACE

# Apply the configuration from the specified folder
echo "Applying configuration from $CONFIG_FOLDER..."
oc apply -f $CONFIG_FOLDER -n $NAMESPACE

echo "OpenShift GitOps installation and configuration complete."