#!/usr/bin/env bash
# (c) 2023 github.com/varcharlie
# Free to use and distribute with no attribution, just don't take all the credit :)
# TODO:
# - intelligently find users SSH keys and add the to SSH_KEYS for them
declare ans=
declare bp=~/.bash_profile
declare errlog=install_errors
declare -r conf=~/.ssh/config
declare -a keys=()

handle_dir() {
    if [ $# -eq 1 ]; then
        # make path relative to homedir
        local dir=$1
        for f in $(ls $dir); do
            local ftype=$(file ${dir}/${f})
            if test -f ${dir}/$f; then
                if echo $ftype | grep -qi 'private key'; then
                    # Private key
                    echo '[!] Found ssh private key '${dir}/${f}
                    keys=(${keys[@]} "${dir}/${f}")
                elif echo $ftype | grep -qi 'public key'; then
                    : # public key expected
                elif echo $ftype | grep -qi 'ascii'; then
                    : # config or environemnt
                else
                    # Unexpected filetype
                    echo "\t$ftype" >> $errlog
                fi
            elif test -d ${dir}/${f}; then
                handle_dir ${dir}/${f}
            elif test -S ${dir}/${f}; then
                : # Found a control socket
            else
                # Unknown filetype? skip it
                echo 'Unknown file type: '${dir}/${f} >> $errlog
                echo 'Filetype: '`file ${dir}/${f}` >> $errlog
            fi
        done
    else
        >>$errlog echo "Error: $BASH_LINENO"
        >>$errlog echo "handle_dir takes a directory as an argument"
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
handle_dir ~/.ssh
declare declare_stmt="declare -a SSH_KEYS=(${keys[@]})"

# modify bash profile;
>>$bp cat<<-EOF
		# ====================================================================
		# SSH-AGENT KEEPALIVE SSH_KEY management
		# --------------------------------------------------------------------
		# Every time you generate a new SSH key please add it to SSH_KEYS
		#
		# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
		EOF
echo $declare_stmt >> $bp && echo '[!] Ran `echo '${declare_stmt}' >> '${bp}'`'
tail -n +2 ssh-agent-keepalive >> $bp && echo '[!] Ran `tail -n +2 ssh-agent-keepalive >> '${bp}'`'


# modify ssh config;
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
            {
                >>$conf cat <<-EOF
				Host *
				    ForwardAgent yes
				EOF
            } && echo "[!] Added SSH Agent forwarding to $conf" && \
                 echo '[!] Done, SSH-AGENT-KEEPALIVE is enabled'
        fi
    fi
fi
