path "auth/approle/role/app1node1.mustach.io/role-id" {
    capabilities = ["read"]
}
path "auth/approle/role/app1node1.mustach.io/secret-id" {
    capabilities = ["update"]
}

path "auth/approle/role/app1node2.mustach.io/role-id" {
    capabilities = ["read"]
}

path "auth/approle/role/app1node2.mustach.io/secret-id" {
    capabilities = ["update"]
}
