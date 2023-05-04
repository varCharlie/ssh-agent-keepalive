# SSH-AGENT KEEPALIVE


**SSH-AGENT KEEPALIVE** is a collection of bash functions and commands that
manage a single ssh-agent process through a hashed environment and
proactively kills off all non-managed (non-cached) ssh-agent pids

## Install
 - Remove any logic from your ~/.bash_profile that starts ssh-agent

 - Edit `ssh-agent-keepalive` and uncomment the line that creates the bash var
   named ${SSH_KEYS}. Add your SSH keys to this variable (on line 43).

 - Run `./install.sh`, this appends `ssh-agent-keepalive` to the end of your
   ~/.bash_profile.
 
 - Ensure agent forwarding is enabled in your ssh config (~/.ssh/config)
   ```bash
   # ~/.ssh/config
   Host *
       ForwardAgent yes
   ```
   `man 5 ssh-config` for help

 - (Optional) Edit ~/.bash_profile to place the ssh-agent-keepalive logic before
   any other operations (such as sourcing bashrc or other files)


## Example output:

If you've set it up properly and open a new terminal window you should see
output like this:

```
Last login: Wed May  3 19:15:41 on ttys079
[+] Starting ssh agent...
[!] Saved ssh env at /Users/user/.ssh/env, agent pid
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

Opening more new windows should look something like this:

```
Last login: Wed May  3 19:15:45 on ttys080
[!] Found running ssh-agent(s)...
[!] Found cached ssh-agent env, sourcing...
[!] Attached to cached ssh-agent

username@hostname: ~ $
```

However if you had multiple ssh-agents running you would see something like this:

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
