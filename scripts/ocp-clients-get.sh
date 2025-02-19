#!/bin/bash
set -x 

export BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
mkdir -p "$BIN_DIR"

# OpenShift Installer
if ! command -v openshift-install &> /dev/null; then
    mkdir -p "/tmp/openshift-installer"
    wget -q --show-progress -O "/tmp/openshift-installer/openshift-install-linux.tar.gz" "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/openshift-install-linux.tar.gz"
    tar zxvf "/tmp/openshift-installer/openshift-install-linux.tar.gz" -C "/tmp/openshift-installer"
    mv  "/tmp/openshift-installer/openshift-install" "$BIN_DIR"
    rm "/tmp/openshift-installer/openshift-install-linux.tar.gz"
fi

# Credentials Operator CLI
if ! command -v ccoctl &> /dev/null; then
    mkdir -p "/tmp/ccoctl"
    wget -q --show-progress -O "/tmp/ccoctl/ccoctl-linux.tar.gz" "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/ccoctl-linux.tar.gz"
    tar zxvf "/tmp/ccoctl/ccoctl-linux.tar.gz" -C "/tmp/ccoctl"
    mv "/tmp/ccoctl/ccoctl" "$BIN_DIR"
    rm "/tmp/ccoctl/ccoctl-linux.tar.gz"
fi

# OpenShift CLI
if ! command -v oc &> /dev/null || ! command -v kubectl &> /dev/null; then
    mkdir -p "/tmp/oc"
    wget -q --show-progress -O "/tmp/oc/openshift-client-linux.tar.gz" "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/openshift-client-linux.tar.gz"
    tar zxvf "/tmp/oc/openshift-client-linux.tar.gz" -C "/tmp/oc"
    mv "/tmp/oc/oc" "$BIN_DIR"
    mv "/tmp/oc/kubectl" "$BIN_DIR"
    rm "/tmp/oc/openshift-client-linux.tar.gz"
fi

$BIN_DIR/openshift-install version

echo "OpenShift Clients Downloaded"