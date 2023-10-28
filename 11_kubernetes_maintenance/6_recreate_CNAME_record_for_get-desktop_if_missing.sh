 FQDN=get-desktop.vocon-it.com
 CONTENT=node1.prod.vocon-it.com
 AUTH='scBFFQEPdFTtvmdg-qLFcrgPbONMNEzHX-r8ab6E'
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
