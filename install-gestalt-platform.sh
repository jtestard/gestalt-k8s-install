#!/bin/bash

exit_with_error() {
  echo "[Error] $1"
  exit 1
}

exit_on_error() {
  if [ $? -ne 0 ]; then
    exit_with_error $1
  fi
}

check_for_kube() {
  echo "Checking for Kubernetes..."

  kubectl cluster-info > ./tmp/cluster-info
  exit_on_error "Kubernetes cluster not accessible, aborting."

  echo ""
  cat ./tmp/cluster-info

  echo ""
  echo "OK - Kubernetes cluster is accessible."
}

check_for_helm() {
  echo "Checking for Helm..."
  helm >/dev/null 2>&1
  exit_on_error "'helm' could not be found. Install helm first."

  helm version > /dev/null
  exit_on_error "'helm' doesn't seem to be configured. Try running 'helm version' or 'helm init'"

  echo "OK - Helm is installed."
}

check_for_existing_namespace() {
  echo "Checking for existing Kubernetes namespace '$namespace'..."
  kubectl get namespace $namespace > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo ""
    echo "Kubernetes namespace '$namespace' already exists, aborting.  To delete the namespace, run the following command:"
    echo ""
    echo "  kubectl delete namespace $namespace"
    echo ""
    exit_with_error "Kubernetes namespace '$namespace' already exists, aborting."
  fi
  echo "OK - Kubernetes namespace '$namespace' does not exist."
}

prompt_to_continue(){
  echo ""
  echo "Gestalt Platform is ready to be installed in the '$namespace' namespace."
  echo ""

  while true; do
      read -p "$* Proceed with Gestalt Platform installation? [y/n]: " yn
      case $yn in
          [Yy]*) return 0  ;;
          [Nn]*) echo "Aborted" ; exit  1 ;;
      esac
  done
}

process_kubeconfig() {
  echo "Processing kubectl configuration (this gets passed to the installer)..."

  os=`uname`
  outfile=./tmp/kubeconfig.yaml

  kubectl config view --raw > ./tmp/kubeconfig
  exit_on_error "Could not process kube config, aborting."

  if [ "$os" == "Darwin" ]; then
    data=`base64 ./tmp/kubeconfig`
  elif [ "$os" == "Linux" ]; then
    data=`base64 -w0 ./tmp/kubeconfig`
  else
    exit_with_error "Could not handle OS type '$os', aborting."
  fi

  cat > $outfile << EOF
# data encoded from $1
kubeconfig: $data
EOF

  echo "Kubernetes config written to $outfile."
}

create_namespace() {
    echo "Creating namespace '$namespace'..."
    echo ""
    kubectl create namespace $namespace
    exit_on_error "Error creating namespace '$namespace', aborting."

    # Wait for namespace to be created
    sleep 5
    echo "Namespace $namespace created."
}

run_helm_install() {
  notes=GESTALT_ACCESS_INFO.txt
  cmd="helm install --namespace $namespace ./gestalt -n gestalt-platform -f ./tmp/kubeconfig.yaml -f ./tmp/gestalt-config.yaml"

  echo "Installing Gestalt Platform to Kubernetes using Helm..."
  echo "  Command: $cmd"
  $cmd | tee -a $notes
  exit_on_error "Installation failed!"

  echo ""
  echo "Gestalt Platform installation completed. Install notes saved to '$notes'."
}

. gestalt-config.sh

namespace=gestalt-system

mkdir -p ./tmp
exit_on_error "Could not create './tmp', aborting. Check filesystem permissions and try again."

check_for_kube

check_for_helm

check_for_existing_namespace

prompt_to_continue

process_kubeconfig

generate_gestalt_config > ./tmp/gestalt-config.yaml

create_namespace

run_helm_install