#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPO_DIR=$(dirname $DIR)

# If there is an .envrc, source it (don't trust direnv)
if [ -f "$REPO_DIR/.envrc" ]; then
    source "$REPO_DIR/.envrc"
fi

# Expected settings
export OCP_CONFIG=${OCP_CONFIG:-"default"}

# Ergonomic settings
export CASE_NAME=${CASE_NAME:-"ocp-lab"}
export DATE_STAMP=$(date +%Y%m%d)
export DATA_DIR="$REPO_DIR/tmp/$DATE_STAMP"

export AWS_REGION=${AWS_REGION:-"us-east-1"}
export SSH_KEY=$(cat $HOME/.ssh/id_rsa.pub)
export PULL_SECRET=${PULL_SECRET:-$(cat "$HOME/.openshift/pull-secret-latest.json")}

export CLUSTER_NAME="${CLUSTER_NAME:-"$CASE_NAME-$(date +%H%M)-$OCP_CONFIG"}"
export CLUSTER_DIR="$DATA_DIR/$CLUSTER_NAME"
export AWS_CP_INSTANCE_TYPE=${AWS_CP_INSTANCE_TYPE:-"r7a.2xlarge"}
export AWS_CP_INSTANCE_ARCH=${AWS_CP_INSTANCE_ARCH:-"amd64"}
export AWS_WK_INSTANCE_TYPE=${AWS_CP_INSTANCE_TYPE:-"r7a.2xlarge"}
export AWS_WK_INSTANCE_ARCH=${AWS_CP_INSTANCE_ARCH:-"amd64"}


CONFIG_DIR="$REPO_DIR/ocp/$OCP_CONFIG"

echo "Generating cluster configuration [$OCP_CONFIG]"
echo "  CLUSTER_NAME[$CLUSTER_NAME]"
echo "  CLUSTER_DIR[$CLUSTER_DIR]"

mkdir -p "$CLUSTER_DIR/log"

envsubst < $CONFIG_DIR/install-config.env.yaml > $CLUSTER_DIR/install-config.yaml
cp $CLUSTER_DIR/install-config.yaml $CLUSTER_DIR/install-config.bak.yaml


echo "OpenShift version check"
openshift-install version | tee $CLUSTER_DIR/log/openshift-version.log.txt

echo "Auto-destroy script [$CLUSTER_DIR/destroy.sh]"
echo "openshift-install destroy cluster --dir=$CLUSTER_DIR" > $CLUSTER_DIR/destroy.sh
chmod +x $CLUSTER_DIR/destroy.sh

echo "Creating cluster..." | tee $CLUSTER_DIR/log/cluster-name.log.txt
aws sts get-caller-identity | tee $CLUSTER_DIR/log/aws-identity.log.txt
echo "  CLUSTER_NAME[$CLUSTER_NAME]"
echo "  CLUSTER_DIR[$CLUSTER_DIR]"
sleep 15

start_time=$(date +%s)
openshift-install create cluster --dir=$CLUSTER_DIR | tee $CLUSTER_DIR/log/create-cluster.log.txt
end_time=$(date +%s)

execution_time=$((end_time - start_time))
execution_time_minutes=$(echo "scale=2; $execution_time / 60" | bc)

command_exit_status=$?

if [ $command_exit_status -ne 0 ]; then
    echo "Command failed with exit code $command_exit_status."
    exit $command_exit_status
fi

if [ $execution_time -lt 300 ]; then
    echo "Execution time too low. Something went wrong."
    exit 1
fi

echo "Case [$CLUSTER_NAME][$(date)] cluster created."
echo "Creation time: $execution_time_minutes minutes"

# replace default kube config
# cp $CLUSTER_DIR/auth/kubeconfig $KUBECONFIG $HOME/.kube/config
echo "Setting new cluster as system default" 
export KUBECONFIG=$CLUSTER_DIR/auth/kubeconfig
ln -sf $HOME/.kube/config $KUBECONFIG 

# Check status
$CLUSTER_DIR/bin/oc status | tee $CLUSTER_DIR/log/oc-status.log.txt

# echo "Executing test..."
# sleep 15

# if [ -f "$CLUSTER_DIR/case-main.sh" ]; then
#     echo "Executing main case hook [$CLUSTER_DIR/case-main.sh]"
#     source "$CLUSTER_DIR/case-main.sh" | tee $CLUSTER_DIR/log/case-main.log.txt
# fi

# echo "Case [$CLUSTER_NAME][$(date)] collecting must gather..."
# $CLUSTER_DIR/bin/oc adm must-gather | tee $CLUSTER_DIR/log/must-gather.log.txt
# mv must-gather* $CLUSTER_DIR/log/

# if [ -f "$CLUSTER_DIR/lab.cluster.retain" ]; then
#    info "Retaining cluster [$CLUSTER_NAME]"
#    info "When ready to dispose, use the following command"
#    info "$CLUSTER_DIR/bin/openshift-install destroy cluster --dir=$CLUSTER_DIR"
#else
#    info "Deleting cluster [$CLUSTER_NAME]"
#    $CLUSTER_DIR/bin/openshift-install destroy cluster --dir=$CLUSTER_DIR
#fi

#echo "Case [$CLUSTER_NAME] considering pruning..."
#if [ -f "$CLUSTER_DIR/case-prune.sh" ]; then
#    echo "Executing prune case hook [$CLUSTER_DIR/case-prune.sh]"
#    source "$CLUSTER_DIR/case-prune.sh" | tee $CLUSTER_DIR/log/case-prune.log.txt
#fi


#echo "Case [$CLUSTER_NAME] done!"
echo "export KUBECONFIG=$CLUSTER_DIR/auth/kubeconfig" 

echo "Cluster [$CLUSTER_NAME] created."

