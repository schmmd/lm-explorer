#
# This script exists to perform variable substitution on a Kubernetes configuration
# before sending it to the kubectl command.
#

#!/bin/bash
set -e

# Get the path to this script.
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

usage() {
  echo ""
  echo "Usage:"
  echo "  ./deploy.sh DOMAIN"
  echo ""
  echo "  DOMAIN  the desired domain, i.e. 'lm-explorer.dev.apps.allenai.org'"
  echo ""
}

domain=$1
if [[ -z "$domain" ]]; then
  echo "Error: no domain specified."
  usage
  exit 1
fi

# Disable failing on errors since Kubernetes has a bug and dies when a namespace doesn't exist.
# See TODO(michaels).
set +e
kubectl get namespace/lm-explorer &> /dev/null
namespace_exists=$?
set -e
if [[ "$namespace_exists" != "0" ]]; then
  echo "creating lm-explorer namespace..."
  kubectl create namespace lm-explorer
else
  echo "namespace lm-explorer already exists..."
fi;

# Substitute variables with information passed in and forward the configuration to kubectl.
sed "s#%DOMAIN%#$domain#g" < $dir/kube.yaml | kubectl apply -f -
