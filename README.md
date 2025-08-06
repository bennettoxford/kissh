# KISSH: Keep It Simple SSH

NOTE: (2021-03-24) this is a draft of our ssh policy and tooling, and is not
enforced yet, but you should go ahead and create keys in advance of the new
policy coming into effect. Policy should start to be the only way sometime in
April 2021.

We use SSH as primary access to all our Datalab infrastructure and as well as
parts of the OpenSAFELY backend infrastructure. We also use it for Github
authentication for cloning and pushing.

Thus, keeping our SSH keys and usage secure is very important. This document
describes our policy for SSH key management.


## The Key

You should have a dedicated Datalab SSH key for use with Datalab systems, and
not with other systems. This should be a modern ed25519 key, protected by
a strong passphrase, and have your Datalab email address and creation date in
the key's comment.

To generate such a key, you can run this in a terminal:

    ssh-keygen -t ed25519 -C "YOUREMAIL@thedatalab.org:$(date +%Y-%m-%d)" -f ~/.ssh/datalab_ed25519

Note: you MUST enter a strong password when prompted.


## Add to your Github Account

We use Github as a key distribution mechanism. You should add the contents of
your public key file (e.g. `~/.ssh/datalab_ed25519.pub`) to your Github
account:

[ https://github.com/settings/keys ](https://github.com/settings/keys)

Github doesn't preserve the key comment, so we recommend titling the key with
the comment, e.g.

     YOUREMAIL@thedatalab.org:202X-XX-XX


## Confirm your Key

Clone this repo and run the following to a ensure your new keys fingerprint is
added:

    GITHUB_USERNAME=<YOUR_GITHUB_USERNAME>
    git clone git@github.com:bennettoxford/kissh.git
    cd kissh

    ./kissh update $GITHUB_USERNAME ~/.ssh/datalab_ed25519.pub

This is should ensure your user has a correct entry with key fingerprint in the
`passwd` file, marking this key as your current Datalab key.

Next, add the public key to this repo:

    git checkout -b "add-$GITHUB_USERNAME-key"
    git add -p
    git commit -m "Add $GITHUB_USERNAME SSH key"
    git push --set-upstream origin "add-$GITHUB_USERNAME-key"

Open a PR and request a review in your team's #code-reviews channel. Once
this is reviewed and merged, after a short time your account and key
should be available to log in with on all our servers.

## Local SSH Config

You can use your local SSH config to ensure you use the right username and key when
accessing Datalab systems with the following snippet in `~/.ssh/config`

```
Host *.ebmdatalab.net *.opensafely.org
    User YOUR_GITHUB_USERNAME
    IdentityFile ~/.ssh/datalab_ed25519
    IdentitiesOnly yes
```

This should allow you to just do `ssh somehost.ebmdatalab.net` and it Just Works.


## Sudo Access and Passwords

By default, all of the tech team at the Datalab have sudo access on all our
infrastructure. We do not enabled passwordless sudo however - you need to set
a password.

For each server, the first time you log in via SSH, you will need to set
a password. It should be a strong password, but bear in mind you will need to
type it in by hand, most likely. It is acceptable to reuse the same password
across multiple server - the main purpose is to require a password for sudo
usage.

If you ever lose or forget your password for a server, you can ask one of the
tech team to run the following on that server:

    sudo passwd -de YOUR_GITHUB_USERNAME

This will delete your password and force a reset next time you SSH in.

## Key Compromise and Rotation

If your key is ever compromised (e.g. your computer is stolen or hacked), you
should inform Simon or Tom W ASAP, and immediately remove the public key from
your Github account, and also the fingerprint from this repo. Either of these
actions will cause the key to be removed from our various systems within
a short window. You can then add a new key as above.


You are encouraged to rotate your keys at least once every 12 months, ideally
more regularly.  You can rotate your key by generating it as above, and adding
it to Github and updating the fingerprint in this repo as described. After
a short while, your old key will be removed from our systems and your new key added.
You can then remove the old key from your github account.


## SSH Agents and Forwarding

Local SSH agents are encouraged, but you should *not* use agent forwarding by
default, as this [presents a significant
risk](https://smallstep.com/blog/ssh-agent-explained/#agent-forwarding-comes-with-a-risk).

You may occasionally need to use your SSH key on a remote server, e.g. to
commit and push changes made to repos on those remote machines.

To do so safely, you should temporarily re-connect with agent forwarding
enabled (`ssh -A ...`), then exit and go back to regular non-forwarded SSH
connection afterwards.


## The kissh agent

To install kissh on a machine, you will need git and python3.5+ installed.
Checkout this repository *as root*:

    sudo git clone https://github.com/bennettoxford/kissh /srv/kissh

Then run the install script:

    cd /srv/kissh
    sudo ./install.sh

This will do an initital run of kissh, validate it, and install a systemd timer
to run the kissh agent periodically. When run, the kissh agent will first
update itself to the latest master, and ensure users and keys are up to date,
creating new users if necessary. It will never remove users, only their keys.
It ensures that **only** the keys approved in this repo are installed - all
other SSH keys will be removed, by design.

Before running, the kissh service will update itself to a clean checkout of the
main branch of the repo, in order to get new user and keys info, as well as
update itself to the latest version. It will discard any local changes, by
design.

The kissh agent has help text for futher information:

    ./kissh --help


## Tests

We use docker to simulate a clean system to run on in test.

To run all tests:

    make test

To run specific test:

    make tests/install.sh

To run test and drop into shell after running test:

    make tests/install.sh DEBUG=1
