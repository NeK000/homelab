#!/bin/bash
set -e

echo "🔐 Creating Sealed Secret from .env"

# Check if .env exists
if [ ! -f my.env ]; then
  echo "❌ Error: my.env file not found"
  exit 1
fi
echo "Remove trailing spaces from my.env"
sed -i 's/[[:space:]]*$//' my.env

# Find the sealed-secrets pod in the sealed-secrets namespace (using Helm-deployed controller)
echo "🔍 Finding Sealed Secrets controller..."
POD=$(kubectl get pods -n sealed-secrets -l app.kubernetes.io/name=sealed-secrets -o jsonpath='{.items[0].metadata.name}')
if [ -z "$POD" ]; then
  echo "❌ Sealed Secrets controller not found in sealed-secrets namespace"
  exit 1
fi
echo "✅ Found pod: $POD"

echo "📜 Fetching certificate via port-forward..."
kubectl port-forward -n sealed-secrets "$POD" 8080:8080 &
PF_PID=$!
sleep 3

curl -s http://localhost:8080/v1/cert.pem > /tmp/pub-cert.pem
kill $PF_PID 2>/dev/null || true

echo "📝 Creating secret from .env..."
cat > /tmp/secret.yaml <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: secrets
  namespace: sealed-secrets
  annotations:
    reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
    reflector.v1.k8s.emberstack.com/reflection-auto-enabled: "true"
    reflector.v1.k8s.emberstack.com/reflection-auto-namespaces: "mealie,karakeep,actual,homepage,postgres,vaultwarden,tailscale"
type: Opaque
stringData:
EOF

while IFS='=' read -r key value; do
  if [[ -n "$key" && ! "$key" =~ ^# ]]; then
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    echo "  $key: \"$value\"" >> /tmp/secret.yaml
  fi
done < my.env

# Seal it
echo "🔒 Sealing secret..."
mkdir -p clusters/k3s/infrastructure/shared-secrets
kubeseal --format=yaml --cert=/tmp/pub-cert.pem < /tmp/secret.yaml > clusters/k3s/infrastructure/shared-secrets/sealed-secret.yaml

rm /tmp/secret.yaml /tmp/pub-cert.pem

echo "✅ Sealed secret created at: clusters/k3s/infrastructure/shared-secrets/sealed-secret.yaml"
echo "📤 Don't forget to commit and push to trigger Flux!"