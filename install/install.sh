# adapted from kserve's quick_install.sh
# link: https://github.com/kserve/kserve/blob/master/hack/quick_install.sh

set -e

#export ISTIO_VERSION=1.9.0
export ISTIO_VERSION=1.6.2
export KNATIVE_VERSION=knative-v1.0.0
export KSERVE_VERSION=v0.8.0
export CERT_MANAGER_VERSION=v1.3.0


curl -L https://git.io/getLatestIstio | sh -

# Create istio-system namespace
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: istio-system
  labels:
    istio-injection: disabled
EOF

echo "installing istio"

istio-${ISTIO_VERSION}/bin/istioctl manifest apply -f istio-operator.yaml


echo "installing Knative"

kubectl apply --filename https://github.com/knative/serving/releases/download/${KNATIVE_VERSION}/serving-crds.yaml
kubectl apply --filename https://github.com/knative/serving/releases/download/${KNATIVE_VERSION}/serving-core.yaml
kubectl apply --filename https://github.com/knative/net-istio/releases/download/${KNATIVE_VERSION}/release.yaml


echo "install Cert Manager"

kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.yaml
kubectl wait --for=condition=available --timeout=600s deployment/cert-manager-webhook -n cert-manager


echo "installing KServe"

KSERVE_CONFIG=kserve.yaml

# Retry in order to handle that it may take a minute or so for the TLS assets required for the webhook to function to be provisioned
for i in 1 2 3 4 5 ; do
  kubectl apply -f https://github.com/kserve/kserve/releases/download/${KSERVE_VERSION}/${KSERVE_CONFIG} && break || sleep 15;
done

# Install KServe built-in servingruntimes
kubectl wait --for=condition=ready pod -l control-plane=kserve-controller-manager -n kserve --timeout=300s
kubectl apply -f https://github.com/kserve/kserve/releases/download/${KSERVE_VERSION}/kserve-runtimes.yaml
# Clean up


echo "clean up"

rm -rf istio-${ISTIO_VERSION}

echo "Done"
