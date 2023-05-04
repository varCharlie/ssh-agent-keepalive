# SSH-AGENT KEEPALIVE


**SSH-AGENT KEEPALIVE** is a collection of bash functions and commands that
manage a single ssh-agent process through a hashed environment and
proactively kills off all non-managed (non-cached) ssh-agent pids

## Install
 - Remove any logic from your ~/.bash_profile that starts ssh-agent or invokes ssh-add
 
 - Run `./install.sh`:
   - The installer will first check for logic in your `.bash_profile` that invokes ssh-agent
     or ssh-add, installer exits if this logic is still present. Please remove it
   - The installer will then check your `~/.ssh` directory for private keys and create
     a variable named SSH_KEYS, this variable is placed in your `bash_profile`
   - Next the installer copies the contents of `ssh-agent-keepalive` to your `.bash_profile`
     while maintaining a backup of your original at `~/.bash_profile~`
   - Finally the installer inspects your `~/.ssh/config` to ensure ForwardAgent is set to yes
     - If ForwardAgent is set to yes then you're done!
     - If ForwardAgent is set to no you will be prompted for permission to change it
     - If there is no ForwardAgent set then `SSH-AGENT-KEEPALIVE` will either add it under
       `Host *` or add a new config with ForwardAgent enabled under `Host *`.
 
 - Extra Setup: You may consider setting ControlMaster, ControlPath, ControlSocket in your
   ssh-config (`man 5 ssh-config`) to enable connection multiplexing. This will also improve
   your SSH experience.


## Example output:

If you've set it up properly and open a new terminal window you should see
output like this:

```
Last login: Wed May  3 19:15:41 on ttys079
[+] Starting ssh agent...
[!] Saved ssh env at /Users/user/.ssh/env, agent pid 83610
Enter passphrase for /Users/user/.ssh/id_sys:
Identity added: /Users/user/.ssh/id_sys (<censored>)
Enter passphrase for /Users/user/.ssh/id_gitlab:
Identity added: /Users/user/.ssh/id_gitlab (<censored>)
Enter passphrase for /Users/user/.ssh/varcharlie_github/id_varcharlie:
Identity added: /Users/user/.ssh/varcharlie_github/id_varcharlie (<censored>)

username@hostname: ~ $
```

Congrats! It's working and you've successfully added your keys!

If your ssh keys don't have a password attached to them the will be added with
no user prompting.

Opening more new windows might look something like this:

```
Last login: Wed May  3 19:15:45 on ttys080
[!] Found running ssh-agent(s)...
[!] Found cached ssh-agent env, sourcing...
[!] Attached to cached ssh-agent

username@hostname: ~ $
```

However if you had multiple ssh-agents running you might see something like this:

```
Last login: Wed May  3 19:18:20 on ttys081
[!] Found running ssh-agent(s)...
[!] Found cached ssh-agent env, sourcing...
[X] Killed stale ssh-agent with pid 71874
[X] Killed stale ssh-agent with pid 71876
[X] Killed stale ssh-agent with pid 71878
[X] Killed stale ssh-agent with pid 71880
[!] Attached to cached ssh-agent

$ user on cpantoga in ~
07:18:20 ❯❯
```

You shouldn't expect to see any stale pids killed on the first login shell after installation
since `SSH-AGENT-KEEPALIVE` will kill all agents and start a new one if an env cache is not found.
