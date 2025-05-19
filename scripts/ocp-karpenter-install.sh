#!/usr/bin/env bash
set -ex
if [ -n "$ZSH_VERSION" ]; then
    DIR="$( cd "$( dirname "${(%):-%N}" )" >/dev/null 2>&1 && pwd )"
else
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
fi
REPO_DIR=$(dirname $DIR)

# from https://mtulio.dev/guides/ocp-lab-scaling-setup-karpenter/


VERSION=$(openshift-install version | grep openshift-install | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
echo "OpenShift version: $VERSION"

PULL_SECRET_FILE="${HOME}/.openshift/pull-secret-latest.json"
RELEASE_IMAGE=quay.io/openshift-release-dev/ocp-release:${VERSION}-x86_64

CLUSTER_DIR=${CLUSTER_DIR:-$REPO_DIR/tmp/latest}
INSTALL_DIR=$CLUSTER_DIR
METADATA_JSON=${METADATA_JSON:-$CLUSTER_DIR/metadata.json}
CLUSTER_NAME=$(jq -r '.clusterName' $METADATA_JSON)
CLUSTER_BASE_DOMAIN=devcluster.openshift.com
echo "Cluster name: $CLUSTER_NAME"


SSH_PUB_KEY_FILE=$HOME/.ssh/id_rsa.pub

REGION="us-east-1"
export AWS_REGION=$REGION
echo "AWS region: $REGION"

mkdir -p $INSTALL_DIR && cd $INSTALL_DIR

oc adm release extract \
    --tools quay.io/openshift-release-dev/ocp-release:${VERSION}-x86_64 \
    -a ${PULL_SECRET_FILE}

echo ">>> done"

exit 0

###





tar xvfz openshift-client-linux-${VERSION}.tar.gz
tar xvfz openshift-install-linux-${VERSION}.tar.gz

echo "> Creating install-config.yaml"
# Create a single-AZ install config
mkdir -p ${INSTALL_DIR}
cat <<EOF | envsubst > ${INSTALL_DIR}/install-config.yaml
apiVersion: v1
baseDomain: ${CLUSTER_BASE_DOMAIN}
metadata:
  name: "${CLUSTER_NAME}"
platform:
  aws:
    region: ${REGION}
    propagateUserTags: true
    userTags:
      cluster_name: $CLUSTER_NAME
      Environment: cluster
publish: External
pullSecret: '$(cat ${PULL_SECRET_FILE} |awk -v ORS= -v OFS= '{$1=$1}1')'
sshKey: |
  $(cat ${SSH_PUB_KEY_FILE})
EOF

echo ">> install-config.yaml created: "
cp -v ${INSTALL_DIR}/install-config.yaml ${INSTALL_DIR}/install-config.yaml-bkp

./openshift-install create cluster --dir $INSTALL_DIR --log-level=debug

export KUBECONFIG=$PWD/auth/kubeconfig