#!/usr/bin/env bash

export PATH="${PATH}:/usr/sbin"
CLOUDFLARE_API_TOKEN=scBFFQEPdFTtvmdg-qLFcrgPbONMNEzHX-r8ab6E

NAMESPACES_TO_BE_EXCLUDED_BECAUSE_IS_ACTIVE="$(kubectl top pod --all-namespaces --use-protocol-buffers --sort-by=memory | egrep ' intellij-desktop' | awk '{print $1}')"

if [ "$NAMESPACES_TO_BE_EXCLUDED_BECAUSE_IS_ACTIVE" != "" ]; then
  echo NAMESPACES_TO_BE_EXCLUDED_BECAUSE_IS_ACTIVE:
  echo "$NAMESPACES_TO_BE_EXCLUDED_BECAUSE_IS_ACTIVE"
  EXCLUDE_PATTERN=$(echo $NAMESPACES_TO_BE_EXCLUDED_BECAUSE_IS_ACTIVE | sed 's/ /|/g')
  # EXCLUDE_PATTERN looks similar to follows:
  # 'jb9pzsgta2grgaoyyuaz8zvcnqw2|juvonn5uovuv88iaw0tpsjkyqqy1|dswdvqbsd3eoo8xfzfrlkmyybb22'
else
  echo no NAMESPACES_TO_BE_EXCLUDED_BECAUSE_IS_ACTIVE found
  EXCLUDE_PATTERN=EMPTY_EXCLUDE_PATTERN
  # EXCLUDE_PATTERN is 'EMPTY_EXCLUDE_PATTERN', which does not match any namespace name
fi

echo EXCLUDE_PATTERN=$EXCLUDE_PATTERN

#
# Detect Cloudflare CNAMEs to be cleaned
#

MY_IP=$(ifconfig eth0 | head -2 | tail -1 | awk '{print $2}')

# Clean only those entries that are pointing to my own IP address:
MY_IP=$(ifconfig eth0 | head -2 | tail -1 | awk '{print $2}')

[ "${MY_IP}" != "" ] \
&& CLOUDFLARE_CNAMES_TO_BE_CLEANED__NAME_ID_IP="$(
  curl -s -X GET "https://api.cloudflare.com/client/v4/zones/2dd13f4d5a72b13e8684c850823795d4/dns_records?type=CNAME&match=all&per_page=1000" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    | jq -r '.result[] | { name: .name, id: .id, content: .content } | join(" ")' \
    | while read NAME ID CONTENT; do  echo "$NAME $ID $(nslookup $CONTENT | tail -2 | head -1 | cut -d' ' -f2)"; done \
    | grep "${MY_IP}" \
    | egrep '^intellij-desktop-' \
    | egrep -v "${EXCLUDE_PATTERN}"
  )"

#
# Delete obsolete Cloudflare entries
#

echo "CLOUDFLARE_CNAMES_TO_BE_CLEANED__NAME_ID_IP=$CLOUDFLARE_CNAMES_TO_BE_CLEANED__NAME_ID_IP"

echo "$CLOUDFLARE_CNAMES_TO_BE_CLEANED__NAME_ID_IP" \
  | while read NAME ID IP;
    do
      if [ "${ID}" != "" ]; then
        echo
        echo "$NAME   $ID   $IP";
        curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/2dd13f4d5a72b13e8684c850823795d4/dns_records/${ID}" \
          -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
          -H "Content-Type: application/json"
      fi
    done


