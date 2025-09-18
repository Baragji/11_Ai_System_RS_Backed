path "kv/data/platform-api/*" {
  capabilities = ["read", "list"]
}

path "database/creds/platform-api" {
  capabilities = ["read"]
}

path "secret/data/jaeger/*" {
  capabilities = ["read"]
}

path "transit/encrypt/platform-api" {
  capabilities = ["update"]
}

path "transit/decrypt/platform-api" {
  capabilities = ["update"]
}
