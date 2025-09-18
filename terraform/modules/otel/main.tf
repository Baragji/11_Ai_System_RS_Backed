resource "kubernetes_namespace" "observability" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "otel_collector" {
  name       = "otel-collector"
  namespace  = kubernetes_namespace.observability.metadata[0].name
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  version    = var.helm_chart_version

  values = [yamlencode({
    mode = "deployment"
    image = {
      repository = split(":", var.collector_image)[0]
      tag        = split(":", var.collector_image)[1]
    }
    config = {
      receivers = {
        otlp = {
          protocols = {
            grpc = {
              endpoint = "0.0.0.0:4317"
            }
            http = {
              endpoint = "0.0.0.0:4318"
            }
          }
        }
      }
      processors = {
        batch = {
          send_batch_size = 512
          timeout         = "5s"
        }
        attributes = {
          actions = [{
            key    = "service.namespace"
            action = "upsert"
            value  = var.name
          }]
        }
      }
      exporters = {
        logging = {
          loglevel = "warn"
        }
        otlp = {
          endpoint = "${var.jaeger_endpoint}"
          tls = {
            insecure = false
          }
        }
        prometheusremotewrite = {
          endpoint = var.prometheus_endpoint
          tls = {
            insecure_skip_verify = false
          }
        }
        s3 = {
          s3uploader = {
            region        = var.aws_region
            bucket        = element(split(":", var.s3_backup_bucket_arn), length(split(":", var.s3_backup_bucket_arn)) - 1)
            file_prefix   = "telemetry/"
            sse           = "aws:kms"
            kms_key_arn   = var.kms_key_arn
          }
        }
      }
      service = {
        pipelines = {
          traces = {
            receivers  = ["otlp"]
            processors = ["batch", "attributes"]
            exporters  = ["otlp", "s3"]
          }
          metrics = {
            receivers  = ["otlp"]
            processors = ["batch"]
            exporters  = ["prometheusremotewrite", "s3"]
          }
          logs = {
            receivers  = ["otlp"]
            processors = ["batch"]
            exporters  = ["s3"]
          }
        }
      }
    }
    serviceAccount = {
      annotations = {
        "eks.amazonaws.com/role-arn" = var.iam_role_arn
      }
    }
    resources = var.resources
    tolerations = var.tolerations
  })]
}

output "namespace" {
  value = kubernetes_namespace.observability.metadata[0].name
}
