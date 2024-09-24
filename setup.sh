#!/usr/bin/env bash
# (c) 2023 github.com/varcharlie
# Free to use and distribute with no attribution, just don't take all the credit :)
# TODO:
# - intelligently find users SSH keys and add the to SSH_KEYS for them
declare ans=
declare bp=~/.bash_profile
declare -r conf=~/.ssh/config
declare -a keys=()

find_keys() {
    if [ $# -eq 1 ]; then
        local dir=$1
        local ftype=
        local key=
        for f in $(ls $dir); do
            ftype=$(file ${dir}/${f})
            local real_f=${dir}/${f}
            if test -f ${real_f}; then
                if echo $ftype | grep -qi 'private key'; then
                    key=`echo ${real_f} | sed -E 's/\/(home|Users)\/'$(whoami)'/~/'`
                    keys=(${keys[*]} ${key})
                elif echo $ftype | grep -qi 'public key'; then
                    : # public key expected
                elif echo $ftype | grep -qi 'ascii'; then
                    : # config or environemnt
                fi
            elif test -d ${real_f}; then
                find_keys ${real_f};
            elif test -S ${real_f}; then
                : # Found a control socket
            fi
        done
    fi
}

if grep -qE 'ssh-add|ssh-agent' $bp; then
    cat <<-EOF
		[W] WARNING:
		    You still have logic in your $bp invoking ssh-agent and/or ssh-add
		    Please remove this from your $bp before installing.

		[i] SSH-AGENT-KEEPALIVE works by modifying your $bp to manage ssh-agent
		    and ssh-add by itself
	EOF
    exit 1
fi


# Backup user bash_profile
cp $bp ${bp}~

# setup ssh key additions;
find_keys ~/.ssh
declare keys_array="declare -a SSH_KEYS=(${keys[@]})"

# modify bash profile;
>>$bp cat<<-EOF
		# ====================================================================
		# SSH-AGENT KEEPALIVE SSH_KEY management
		# --------------------------------------------------------------------
		# Every time you generate a new SSH key please add it to SSH_KEYS
		#
		# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
		EOF
echo $keys_array >> $bp && echo '[!] Ran `echo '${keys_array}' >> '${bp}'`'
tail -n +2 keepalive >> $bp && echo '[!] Ran `tail -n +2 keepalive >> '${bp}'`'


# modify ssh config;
prompt() {
    read -p "[?] Would you like to enable ForwardAgent for all hosts in ${conf}? (y/n) " ans
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
               echo '[!] Config backed up at '$conf'~';;
            *) echo '[:(] Sorry, SSH-AGENT-KEEPALIVE might not work as expected...';
               exit;;
        esac
    elif grep -q 'ForwardAgent yes' $conf; then
        echo '[i] You have agent forwarding enabled!'
    else
        echo '[!] You have an ssh config that does not have ForwardAgent enabled!'
        if grep 'Host *' $conf; then
            sed -i '~' 's/Host \*/Host *\n\tForwardAgent yes/' $conf && \
            echo '[!] Enabled agent forwarding, config backed up at '$conf'~'
        else
            {
                >>$conf cat <<-EOF
				Host *
				    ForwardAgent yes
				EOF
            } && echo "[!] Added SSH Agent forwarding to $conf"
        fi
    fi
fi
echo '[!] Done, SSH-AGENT-KEEPALIVE is enabled'
