#
# Cookbook:: vagrant_node
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# Shortcut to application settings
as = node[:app1]

directory "#{node['basedir']}/vagrant"

template "#{node['basedir']}/vagrant/Vagrantfile" do
  source 'Vagrant.erb'
  variables vnodes: as['vagrant_nodes']
end

# For each application node, do some setup
as[:vagrant_nodes].each do |n|
  # Create an approle with short lived token for each node, based on policies given
  vault_approle "Vault AppRole: #{n[:node]}.#{n[:domain]}" do
    role_name "#{n[:node]}.#{n[:domain]}"
    address node[:vault_addr]
    token node[:armaint_token]
    bound_cidr_list "#{n[:ip]}/32"
    policies n[:policies]
    secret_id_num_uses 1
    secret_id_ttl '5s'
    token_ttl '30s'
    token_max_ttl '30s'
  end

  # Create Chef node JSON for Vagrant chef-zero provisioning
  template "#{node[:basedir]}/nodes/#{n[:node]}.#{n[:domain]}.json" do
    variables app_name: as[:appname], arstart_token: node[:arstart_token], vnode: n, vault_addr: as[:vault_addr]
    source 'chef_node.json.erb'
  end
end
