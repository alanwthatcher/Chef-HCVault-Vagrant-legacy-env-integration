## Integrating Chef and Vault within a "legacy environment"
This repository is meant to be a sort of test bed for generating and testing ideas around integrating Chef and HashiCorp Vault within a "legacy environmnent". That is, focusing more on deployments of virtual machines in a controlled envrionment instead of something like container based deployments.

## What it doesn't provide
The contents of this repo were developed on a Mac, and haven't been tested on other OS such as linux or Windows.

The cookbooks, scirpts, and such that are provided here assume a few things are already present on the machine on which they will be used.  Those are:
* Vagrant is up and running already: assumed to be Vagrant with VirtualBox provider
  * The default box is bento/centos-7.4
* HashiCorp Vault is also up and running
  * The user executing scripts has the proper environment variable set
  * The user executing scripts has authenticated with Vault with privileges to: mount backends, write secrets generally, manage policies, manage tokens, manage approles
  * The Vault address defaults to be: http://127.0.0.1:8200
  * Vault should be accessible from created Vagrant boxes
* Chef client is already installed, and in the users path

If all of those requirements are already present, then things should go smoothly.

## Tuning for specific environment
A few things can be easily tuned before starting any testing, the are all located in `files/.app1-nodes.json.bak`, which is one of the files used to reset things after testing.
The file is JSON formatted, so here are the main things that might need setting for your specific needs:
* `vault_addr` - Change to meet whatever is required for scripts run on the source machine to reach your Vault instance
* `app1['vault_addr']` - Change to meet whatever is required for a Vagrant box to reach your Vault instance
* `app1['vagrant_nodes`][x]['box']` - Change to meet whatever box you want to use. Testing was only done on CentOS boxes
* `app1['vagrant_nodes'][x]['ip']` - Change if you have conflicts

The rest of the settings should be ok to leave. I use `mustach.io` because I think it's a great word.  Change if it conflicts with something you have.

If you are going to be creating more than the standard app1node1 and app1node2 boxes, or change the mustach.io domain, modify `files/hcl/app1-arstart.hcl` to match.

I plan on making some of these things more automated, but that's how it stands for now.

## Basic use
I've designed this, hopefully, to be a starting point for testing ideas. Meaning that it very generically integrates the three technologies. It's meant to be modified, so if it works for you as a jumping off point, fork it and have a blast :)

Usage it it's most basic form is on this wise:
1. Clone repository to some location on your machine
2. Modify the `files/.app1-nodes.json.bak` as required (see above section)
3. Execute `scripts/basic_setup`.  This will:
    * Mount a Vault kv backend called `app`
    * Write some secrets to that mount: `app1/config` and `app1/secret2`
    * Create a policy called app1-ro, which allows read only access to the secrets in the app1 mount
    * Create a policy called app1-secret1-rw, which allows updating of `app1/secret1`
    * Enables AppRole authentication. If it's already enabled, it errors, but that's ok
    * Creates a policy, `approle-maintain`, and token specifically for creating AppRoles
    * Creates a policy, `app1-arstart`, and token which can start the AppRole authentication for the app1node1 and app1node2 Vagrant boxes
    * Updates the current working directory in the config file, assumes everything will work out of that
4. From the root of the repo, run `chef-client -z -o vagrant_node -j files/app1-nodes.json` which will:
    * Creates Vagrantfile
      * Two boxes: app1node1.mustach.io and app1node2.mustach.io
        * app1node1 is a web server
        * app1node2 is a app server
      * Chef-Zero provisioning to run the cookbook: app1_stack
    * Create an AppRole for each node defined in `files/app1-nodes.json`
      * Each approle is CIDR bound to the specific IP of the box
      * Policies are defined per node, default:
        * app1node1 has `app1-ro`
        * app1node2 has `app1-secret1-rw`
    * Create the node data for the chef-zero client runs
5. From the vagrant directory: `vagrant up`
    * app1node1 will make a basic web server with a index page that has the contents of the secrets: `app1/config` and `app1/secret1`
    * app2node2 will make an "app" server that will update `app1/secret1`
6. From the vagrant directory: `vagrant up app1node1 --provision`
    * app1node1 will re-run the Chef cookbook, and the index file will be updated with the new `app1/secret1` value.
