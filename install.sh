#!/usr/bin/env bash
# (c) 2023 github.com/varcharlie
declare ans=
declare bp=~/.bash_profile
declare -r conf=~/.ssh/config

cp $bp ${bp}~
cat ssh-agent-keepalive >> $bp && echo '[!] Ran `cat ssh-agent-keepalive >> '${bp}'`'

prompt() {
    read -p '[?] Would you like to enable ForwardAgent in all instances? (y/n) ' ans
}

if ! test -e $conf; then
    {
        >$conf cat<<-EOF
		Host *
		    ForwardAgent yes
		EOF
    } && echo "[!] Created ${conf} with ForwardAgent enabled"
else
    if grep -q 'ForwardAgent no' $conf; then
        echo "${conf}:"
        cat $conf
        echo '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'
        echo '[!] Your SSH Config has `ForwardAgent no`'
        echo '[i] SSH-AGENT KEEPALIVE will not work without ForwardAgent enabled'
        prompt
        case $ans in
            y) sed -i '~' 's/ForwardAgent no/ForwardAgent yes/' $conf && \
               echo '[!] Config backed up at '$conf'~'
               echo '[!] Done, SSH-AGENT KEEPALIVE is enabled';;
            *) echo '[:(] Sorry, SSH-AGENT-KEEPALIVE might not work as expected...';;
        esac
        set +x
    elif grep -q 'ForwardAgent yes' $conf; then
        echo '[i] You have agent forwarding enabled!'
        echo '[!] Done, SSH-AGENT-KEEPALIVE is enabled'
    else
        echo '[!] You have an ssh config that does not have ForwardAgent enabled!'
        if grep 'Host *' $conf; then
            sed -i '~' 's/Host \*/Host *\n\tForwardAgent yes/' $conf
            echo '[!] Enabled agent forwarding, config backed up at '$conf'~'
        else
            >>$conf cat <<-EOF
				Host *
				    ForwardAgent yes
			EOF
            echo "[!] Added SSH Agent forwarding to $conf"
            echo '[!] Done, SSH-AGENT-KEEPALIVE is enabled'
        fi
    fi
fi
