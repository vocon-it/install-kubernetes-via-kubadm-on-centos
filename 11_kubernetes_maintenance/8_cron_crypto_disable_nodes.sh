
# find small files looking like crypto config files in jupyter namespaces and set everything to disabled:
sudo find /mnt -type f -size -10k -iname '*.json' \
  | egrep 'jup' \
  | egrep -v 'cache|vscode|mozilla|pkgs|/lib/|\.conda|kernel|noVNC|chrom|/Code/|anaconda3' \
  | xargs egrep -c '"cpu"|"coin"|"rx"|"rx/wow"' \
  | grep -v :0 \
  | cut -d ':' -f1 \
  | while read CONFIG_FILE; 
    do 
      echo $CONFIG_FILE; 
      sed -i 's/\("enabled":\).*$/\1 false,/g' "${CONFIG_FILE}"; 
    done
