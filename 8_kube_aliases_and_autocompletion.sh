

set -e

_NOTHING_TO_DO="Already installed. Nothing to do."

echo "--------------------------------------------------------------"
echo "Checking for kubernetes aliases & functions in ${HOME}/.bashrc"
echo "--------------------------------------------------------------"

cat ${HOME}/.bashrc | grep 'alias k=' >/dev/null \
  && echo "${_NOTHING_TO_DO}" \
  || cat <<'EOF' | tee -a ${HOME}/.bashrc

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
sudo echo hello >/dev/null 2>/dev/null || alias sudo="$@"
yum list installed | grep bash-completion >/dev/null \
  && echo "${_NOTHING_TO_DO}" \
  || sudo yum install -y bash-completion

echo "Installing bash completion in .bashrc"
cat ${HOME}/.bashrc | grep 'source /usr/share/bash-completion/bash_completion' >/dev/null \
  && echo "${_NOTHING_TO_DO}" \
  || cat <<'EOF' | tee -a ${HOME}/.bashrc

# bash completion general:
if type _init_completion >/dev/null 2>/dev/null; then
  echo "bash completion already initialized; nothing to do..."
else
  echo "initializing bash completion (source /usr/share/bash-completion/bash_completion)"
  source /usr/share/bash-completion/bash_completion \
    || echo "Warning: error reading /usr/share/bash-completion/bash_completion"
fi
EOF

echo "Installing bash completion for kubectl in .bashrc"
cat ${HOME}/.bashrc | grep 'source <(kubectl completion bash)' >/dev/null \
  && echo "${_NOTHING_TO_DO}" \
  || cat <<'EOF' | tee -a ${HOME}/.bashrc

# bash completion for kubectl
source <(kubectl completion bash)
EOF


echo "Installing bash completion for alias k=kubectl in .bashrc"
cat ${HOME}/.bashrc | grep 'source <(kubectl completion bash | sed' >/dev/null \
  && echo "${_NOTHING_TO_DO}" \
  || cat <<'EOF' | tee -a ${HOME}/.bashrc
source <(kubectl completion bash | sed 's/kubectl/k/g')
EOF

unset _NOTHING_TO_DO
