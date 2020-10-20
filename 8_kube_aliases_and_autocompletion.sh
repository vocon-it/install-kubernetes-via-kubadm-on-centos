

set -e

_NOTHING_TO_DO="Already installed. Nothing to do."


echo "Checking for kubernetes aliases & functions in ${HOME}/.bashrc"
cat ${HOME}/.bashrc | grep 'alias k=' >/dev/null && echo "${_NOTHING_TO_DO}" || cat <<'EOF' | tee -a ${HOME}/.bashrc

# Kubernetes aliases & functions
alias k=kubectl
EOF


echo "Installing kns()"
cat ${HOME}/.bashrc | grep 'function kns()' >/dev/null \
  && echo "${_NOTHING_TO_DO}" \
  || cat <<'EOF' | tee -a ${HOME}/.bashrc

# Function kns for changing the current kubectl context/namespace
function kns() {
  [ $# -eq 0 ] \
    && kubectl config get-contexts | grep '^\*' | awk '{print $5}' \
    || kubectl config set-context $(kubectl config current-context) --namespace=$1;
}
EOF


echo "Installing bash completion"
sudo yum list installed | grep bash-completion >/dev/null \
  && echo "${_NOTHING_TO_DO}" \
  || sudo yum install -y bash-completion

echo "Installing bash completion for kubectl"
cat ${HOME}/.bashrc | grep 'source <(kubectl completion bash)' >/dev/null \
  && echo "${_NOTHING_TO_DO}" \
  || cat <<'EOF' | tee -a ${HOME}/.bashrc

# bash completion for kubectl
source <(kubectl completion bash)
EOF


echo "Installing bash completion for alias k=kubectl"
cat ${HOME}/.bashrc | grep 'source <(kubectl completion bash | sed' >/dev/null \
  && echo "${_NOTHING_TO_DO}" \
  || cat <<'EOF' | tee -a ${HOME}/.bashrc
source <(kubectl completion bash | sed 's/kubectl/k/g')
EOF

unset _NOTHING_TO_DO
