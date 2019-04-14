
mkdir -p default-certificate; cd default-certificate
[ "$DOMAIN" == "" ] && DOMAIN=example.com
read -N 1 -t 10 -p "What is the the domain of this cluster? [$DOMAIN] > " a
[ "$a" != "" ] && read b && DOMAIN="$a$b"

echo "Domain set to $DOMAIN"

openssl req -x509 -newkey rsa:4096 -sha256 -nodes -keyout tls_self.key -out tls_self.crt -subj "/CN=*.${DOMAIN}" -days 365

kubectl get secret default-server-secret -n nginx-ingress && kubectl delete secret default-server-secret -n nginx-ingress
kubectl create secret generic --type=Opaque default-server-secret --from-file=tls.crt=tls_self.crt --from-file=tls.key=tls_self.key -n nginx-ingress
cd ..
