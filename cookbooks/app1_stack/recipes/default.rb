#
# Cookbook:: app1_stack
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

case node['app1']['node_role']
when 'web'
  # Retrieve secret1 from Vault, pass: addr, token, path, approle
  secret1 = Vaultron::Helpers.read(
    node['vault_addr'],
    node['app1']['arstart_token'],
    'app1/secret1',
    node['fqdn']
  ) 

  # Retrieve config values
  config = Vaultron::Helpers.read(
    node['vault_addr'],
    node['app1']['arstart_token'],
    'app1/config',
    node['fqdn']
  )

  # Install basic httpd package and index.html
  package 'httpd'

  template '/etc/httpd/conf/httpd.conf' do
    source 'httpd.conf.erb'
    notifies :restart, 'service[httpd]'
  end

  service 'httpd' do
    action [:start, :enable]
  end

  template '/var/www/html/index.html' do
    source 'app1_index.html.erb'
    variables config: config, secret1: secret1
  end

when 'app'
  time =  Time.new.strftime("%Y%m%d%H%M%S")
  # Update a value in vault
  vault 'update app1/secret1' do
    action :write
    address node['vault_addr']
    token node['app1']['arstart_token']
    approle node['fqdn']
    path 'app1/secret1'
    payload value: "cookbook update: #{time}"
  end
end
