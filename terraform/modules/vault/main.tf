resource "kubernetes_namespace" "vault" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "vault" {
  name       = "vault"
  namespace  = kubernetes_namespace.vault.metadata[0].name
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = var.helm_chart_version

  values = [yamlencode({
    global = {
      tlsDisable = false
    }
    injector = {
      enabled = true
      agentImage = {
        repository = "hashicorp/vault"
        tag        = var.vault_image_tag
      }
    }
    server = {
      image = {
        repository = "hashicorp/vault"
        tag        = var.vault_image_tag
      }
      extraEnvironmentVars = {
        VAULT_AWSKMS_SEAL_KEY_ID = var.kms_key_arn
      }
      extraVolumes = [
        {
          type = "secret"
          name = kubernetes_secret.vault_tls.metadata[0].name
          path = "tls"
        }
      ]
      ha = {
        enabled = true
        raft = {
          enabled = true
          setNodeId = true
          config = <<EOT
cluster_name = "${var.name}-vault"
storage "raft" {
  path    = "/vault/data"
}
listener "tcp" {
  address                  = "0.0.0.0:8200"
  tls_disable              = "false"
  tls_cert_file            = "/vault/userconfig/tls/tls.crt"
  tls_key_file             = "/vault/userconfig/tls/tls.key"
}
seal "awskms" {
  region     = "${var.aws_region}"
  kms_key_id = "${var.kms_key_arn}"
}
EOT
        }
      }
      auditStorage = {
        enabled = true
        storageClass = var.audit_storage_class
      }
      service = {
        type = "ClusterIP"
      }
      resources = var.server_resources
      affinity = {
        podAntiAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = [{
            labelSelector = {
              matchExpressions = [{
                key      = "app.kubernetes.io/name"
                operator = "In"
                values   = ["vault"]
              }]
            }
            topologyKey = "kubernetes.io/hostname"
          }]
        }
      }
    }
  })]

  set_sensitive {
    name  = "server.extraEnvironmentVars.VAULT_AWSKMS_SEAL_KEY_ID"
    value = var.kms_key_arn
  }
}

resource "kubernetes_secret" "vault_tls" {
  metadata {
    name      = "vault-tls"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  data = {
    "tls.crt" = var.vault_tls_cert
    "tls.key" = var.vault_tls_key
    "ca.crt"  = var.vault_tls_ca
  }
}

output "namespace" {
  value = kubernetes_namespace.vault.metadata[0].name
}
