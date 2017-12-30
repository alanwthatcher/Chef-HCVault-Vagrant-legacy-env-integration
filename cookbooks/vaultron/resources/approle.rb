require 'vault'

resource_name :vault_approle
provides :vault_approle

property :role_name, String, name_property: true
property :address, String
property :token, String
property :approle, String
property :bind_secret_id, [true, false], default: true
property :bound_cidr_list, String
property :policies, Array
property :secret_id_num_uses, Integer
property :secret_id_ttl, String
property :token_num_uses, Integer
property :token_ttl, String
property :token_max_ttl, String
property :period, String

action :create do
  # use Vault singleton
  Vault.address = new_resource.address

  # Auth with token provided
  Vault.token = new_resource.token

  # If approle is passed, use approle login
  if property_is_set?(:approle)
    # Lookup role-id
    approle_id = Vault.approle.role_id(new_resource.approle)

    # Generate a secret-id
    secret_id = Vault.approle.create_secret_id(new_resource.approle).data[:secret_id]

    # Login with approle auth provider
    Vault.auth.approle(approle_id, secret_id)
  end

  # Cobble together approle data, lean on defaults for unspecified properties
  data = {
    "bind_secret_id": new_resource.bind_secret_id,
    "bound_cidr_list": ( new_resource.bound_cidr_list if property_is_set?(:bound_cidr_list) ),
    "policies": ( new_resource.policies if property_is_set?(:policies) ),
    "secret_id_num_uses": ( new_resource.secret_id_num_uses if property_is_set?(:secret_id_num_uses) ),
    "secret_id_ttl": ( new_resource.secret_id_ttl if property_is_set?(:secret_id_ttl) ),
    "token_num_uses": ( new_resource.token_num_uses if property_is_set?(:token_num_uses) ),
    "token_ttl": ( new_resource.token_ttl if property_is_set?(:token_ttl) ),
    "token_max_ttl": ( new_resource.token_max_ttl if property_is_set?(:token_max_ttl) ),
    "period": ( new_resource.period if property_is_set?(:period) )
  }.reject{ |k,v| v.nil? }

  # Write approle
  Vault.logical.write("auth/approle/role/#{new_resource.role_name}", data)
  
  # Fire notification
  updated_by_last_action(true)
end

action :delete do
  # use Vault singleton
  Vault.address = new_resource.address

  # Auth with token provided
  Vault.token = new_resource.token

  # If approle is passed, use approle login
  if property_is_set?(:approle)
    # Lookup role-id
    approle_id = Vault.approle.role_id(new_resource.approle)

    # Generate a secret-id
    secret_id = Vault.approle.create_secret_id(new_resource.approle).data[:secret_id]

    # Login with approle auth provider
    Vault.auth.approle(approle_id, secret_id)
  end

  # Delete approle
  Vault.logical.delete("auth/approle/role/#{new_resource.role_name}")

  # Fire notification
  updated_by_last_action(true)
end
