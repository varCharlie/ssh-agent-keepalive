# SSH-AGENT KEEPALIVE
`SSH-AGENT KEEPALIVE` manages ssh-agent for you so that you have access to
your agent in every terminal session.

## TL;DR Quick Setup & Usage Instructions
#### Setup
- Setup `SSH-AGENT-KEEPALIVE` by running `setup.sh`.
- Attach to the SSH-agent in old terminal windows by running `source ~/.ssh/env`.
  Alternatively you can `source ~/.bash_profile` which will attach to your newly
  spawned SSH-Agent.
- See **Example flow of a first time setup** below for detailed output


## Why use `SSH-AGENT KEEPALIVE`?
  1. Because ssh-agent makes your remote access life easier
  2. Alternative is to source your agent environment manually or source it directly from
     your ~/.bash_profile but what happens when that pid dies and the cache lives?
  3. You can write your own logic to see if the pid is still there but occasionally you'll find
     that you have more than one ssh-agent process running for your user which is wasting
     resources. I've considered those things and accounted for them. 

## Setup
- **IMPORTANT** Remove any logic from your `~/.bash_profile` that starts `ssh-agent` or invokes `ssh-add`
- Run `./setup.sh` which takes the following actions.
 - Verifies `~/.bash_profile` doesn't directly invoke `ssh-agent` or `ssh-add`
 - Backs up `~/.bash_profile` to `~/.bash_profile~`
 - Adds all private keys found in `~/.ssh` to a variable named `SSH_KEYS`
 - Updates your `~/.bash_profile` to install itself
 - Checks if `~/.ssh/config` exists
  - If so it checks if `ForwardAgent` is set to `no` then asks for permission to change this.
    You should only deny permission if you *purposely* don't want agent forwarding for that host.
  - If not it creates a basic `ssh_config` with `ForwardAgent yes` configured for wildcard `Host *`

Additonal considerations:
- For supreme laziness you may want to consider using connection multiplexing.
  "would ya look at that?"- This is disabled on some SSH servers due to "security concerns"
  ^-(as Ed Bassmaster)--^

### SSH Connection Multiplexing via Control Sockets
I've provided an example `ssh_config` in this directory that implements connection multiplexing.
It uses multiplexing based on hostname and persists for 15 minutes after you log out.

```
Host *
    ControlMaster auto
    ControlPath ~/.ssh/ctrl-%h
    ControlPersist 15m
    ForwardAgent yes
    IdentityFile ~/.ssh/<SSH_KEY_HERE>
    User <USERNAME HERE>
```

Refer to `man 5 ssh_config` for help setting up your `ssh_config`.

### Example flow of a first time setup
```
# Example output, first try failed:
user@host:~/git/ssh-agent-keepalive$ ./setup.sh
[W] WARNING:
    You still have logic in your /Users/user/.bash_profile invoking ssh-agent and/or ssh-add
    Please remove this from your /Users/user/.bash_profile before installing.

[i] SSH-AGENT-KEEPALIVE works by modifying your /Users/user/.bash_profile to manage ssh-agent
    and ssh-add by itself
```

```
user@host:~/git/ssh-agent-keepalive$ vim ~/.bash_profile # Removing ssh-agent and ssh-add invocations
```

```
user@host:~/git/ssh-agent-keepalive$ ./setup.sh
[!] Ran `echo declare -a SSH_KEYS=(~/.ssh/id_ed25519 ~/.ssh/id_rsa) >> /Users/user/.bash_profile`
[!] Ran `tail -n +2 keepalive >> /Users/user/.bash_profile`
[i] You have agent forwarding enabled!
[!] Done, SSH-AGENT-KEEPALIVE is enabled
```

### Example output
```
Last login: Wed May  3 19:15:41 on ttys079
[+] Starting ssh agent...
[!] Saved ssh env at /Users/user/.ssh/env, agent pid 83610
Enter passphrase for /Users/user/.ssh/priv1:
Identity added: /Users/user/.ssh/priv1 (<censored>)
Enter passphrase for /Users/user/.ssh/priv2:
Identity added: /Users/user/.ssh/priv2 (<censored>)
Enter passphrase for /Users/user/.ssh/github/priv3:
Identity added: /Users/user/.ssh/github/priv3 (<censored>)
```

```
Last login: Wed May  3 19:15:45 on ttys080
[!] Found running ssh-agent(s)...
[!] Found cached ssh-agent env, sourcing...
[!] Attached to cached ssh-agent
```

```
Last login: Wed May  3 19:18:20 on ttys081
[!] Found running ssh-agent(s)...
[!] Found cached ssh-agent env, sourcing...
[X] Killed stale ssh-agent with pid 71874
[X] Killed stale ssh-agent with pid 71876
[X] Killed stale ssh-agent with pid 71878
[X] Killed stale ssh-agent with pid 71880
[!] Attached to cached ssh-agent
```
