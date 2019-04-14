
#
# defines aliases k=kubectl and function kns for setting the default namespace.
# will persist the changes in $HOME/.bashrc, if the alias k is not yet defined there
#

ALIASES='
# aliases
alias k 1>/dev/null 2>&1 || alias k='\''kubectl'\''

# print or change current namespace:
function kns() {
  [ $# -eq 0 ] \
    && kubectl config get-contexts | grep '\''^\*'\'' | awk '\''{print $5}'\'' \
    || kubectl config set-context $(kubectl config current-context) --namespace=$1;
}
'

if ! cat $HOME/.bashrc | grep -q "alias.*kubectl"; then
  echo "$ALIASES" >> $HOME/.bashrc && source $HOME/.bashrc
fi
