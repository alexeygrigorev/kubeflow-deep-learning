# adapted from kfserving's quick_install.sh
# link: TODO

set -e 

export ISTIO_VERSION=1.6.2
export KNATIVE_VERSION=v0.15.0
export KFSERVING_VERSION=v0.3.0

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


istio-${ISTIO_VERSION}/bin/istioctl manifest apply -f istio-operator.yaml

# Install Knative
kubectl apply --filename https://github.com/knative/serving/releases/download/${KNATIVE_VERSION}/serving-crds.yaml
kubectl apply --filename https://github.com/knative/serving/releases/download/${KNATIVE_VERSION}/serving-core.yaml
kubectl apply --filename https://github.com/knative/net-istio/releases/download/${KNATIVE_VERSION}/release.yaml

# Install Cert Manager
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.1/cert-manager.yaml
kubectl wait --for=condition=available --timeout=600s deployment/cert-manager-webhook -n cert-manager

# Install KFServing
kubectl apply -f https://raw.githubusercontent.com/kubeflow/kfserving/master/install/${KFSERVING_VERSION}/kfserving.yaml

# Clean up
rm -rf istio-${ISTIO_VERSION}
