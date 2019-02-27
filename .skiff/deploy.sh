#!/bin/bash
set -e

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# If $PROJECT_ID is set, we're running in Google Cloud Build, which means
# we need to invole /builder/kubectl.bash instead of the standard kubectl.
# This is because /builder/kubectl.bash includes the right configuration
# for authenticating against the target cluster.
kubectl_cmd="kubectl"
if [[ ! -z "$CLOUDSDK_COMPUTE_ZONE" ]]; then
  kubectl_cmd="/builder/kubectl.bash"
fi

usage() {
  echo ""
  echo "Usage:"
  echo "  ./deploy.sh IMAGE DOMAIN"
  echo ""
  echo "  IMAGE   the image version to deploy, i.e. gcr.io/ai2-reviz/skiff-ui:latest"
  echo "  DOMAIN  the top level domain directed to the cluster, i.e. 'dev.apps.allenai.org'"
  echo ""
}

echo "using '$kubectl_cmd'…"

# Figure out the image we'd like to deploy, and complain if it's empty.
image=$1
if [[ -z "$image" ]]; then
  echo "Error: no image specified."
  usage
  exit 1
fi

domain=$2
if [[ -z "$domain" ]]; then
  echo "Error: no domain specified."
  usage
  exit 1
fi

set +e
$kubectl_cmd get namespace/skiff-ui &> /dev/null
namespace_exists=$?
set -e
if [[ "$namespace_exists" != "0" ]]; then
  echo "creating skiff-ui namespace…"
  $kubectl_cmd create namespace skiff-ui
else
  echo "namespace skiff-ui already exists…"
fi;

echo "deploying '$image' to '$domain'…"

# Deploy the latest UI
sed "s#%IMAGE%#$image#g" < $dir/kube.yaml | sed "s#%DOMAIN%#$domain#g" | $kubectl_cmd apply -f -
