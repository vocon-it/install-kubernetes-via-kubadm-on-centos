

cat <<EOF | kubectl apply -f -
---
apiVersion: certmanager.k8s.io/v1alpha1
kind: Issuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: oliver.veits+letsencrypt-test@vocon-it.com
    privateKeySecretRef:
      name: letsencrypt-staging
    http01: {}
EOF

cat <<EOF | kubectl apply -f -
---
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: letsencrypt-staging-jenkins2
spec:
  secretName: letsencrypt-staging-jenkins2-tls
  issuerRef:
    name: letsencrypt-staging
  commonName: jenkins2.dev.vocon-it.com
  acme:
    config:
      - http01:
          ingress: jenkins2
        domains:
          - jenkins2.dev.vocon-it.com
EOF

