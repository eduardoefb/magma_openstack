cat << EOF >> $HOME/.bashrc
## pyenv configs
export PYENV_ROOT="\$HOME/.pyenv"
export PATH="\$PYENV_ROOT/bin:\$PATH"

if command -v pyenv 1>/dev/null 2>&1; then
   eval "\$(pyenv init -)"
fi
EOF

source $HOME/.bashrc

pyenv install -l

pyenv install 3.7.3
pyenv global 3.7.3

# As root:
# pip3 install ansible fabric3 jsonpickle requests PyYAML boto3