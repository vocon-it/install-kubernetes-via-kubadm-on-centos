FQDN=get-desktop.vocon-it.com
AUTH='scBFFQEPdFTtvmdg-qLFcrgPbONMNEzHX-r8ab6E'

CONTENT=node1.prod.vocon-it.com
curl -s -I -X GET ${CONTENT} | grep -q '404 Not Found' || CONTENT=node2.prod.vocon-it.com
curl -s -I -X GET ${CONTENT} | grep -q '404 Not Found' || NODES_NOT_REACHABLE=true

if [ "${NODES_NOT_REACHABLE}" == "true" ]; then
  echo could not find a valid Ingress node
  echo exiting...
  exit 1
fi

curl --fail -s \
  -H 'Authorization: Bearer '"${AUTH}" \
  -H 'Content-Type: application/json' \
  -X GET 'https://api.cloudflare.com/client/v4/zones/2dd13f4d5a72b13e8684c850823795d4/dns_records?per_page=1000&name='"${FQDN}" \
     | jq -r .result_info.total_count | egrep -q '^0$' \
  && curl --fail -s \
       -X POST https://api.cloudflare.com/client/v4/zones/2dd13f4d5a72b13e8684c850823795d4/dns_records \
       -H 'Authorization: Bearer '"${AUTH}" \
       -H 'Content-Type: application/json' \
       --data '{
	"type":"CNAME",
	"name":"'"${FQDN}"'",
	"content":"'"${CONTENT}"'",
	"ttl":120,
	"priority":10,
	"proxied":false
  }' \
    && echo && echo "WARNING: re-created CNAME Record for ${FQDN} with CONTENT=${CONTENT}"
