#!/usr/bin/env bash
# (c) 2023 github.com/varcharlie
cat ssh-agent-keepalive >> ~/.bash_profile && echo "cat ssh-agent-keepalive >> ~/.bash_profile"

if ! test -f ~/.ssh/config; then
    {
        >>~/.ssh/config cat<<-EOF
		Host *
		    ForwardAgent yes
		EOF
    } && echo "Created ~/.ssh/config with AgentForwarding enabled"
else
    echo
    echo
    echo "Found config at ~/.ssh/config:"
    echo "Please ensure you have 'ForwardAgent yes' on all hosts which use ssh keys for connections!"
    echo
    echo "Example ~/.ssh/config:"
    echo "Host *"
    echo "    ForwardAgent yes"
fi
