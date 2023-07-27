resource "kubernetes_deployment" "docker-registry" {
  metadata {
    name = "docker-registry"
    namespace   = var.namespace
    labels = {
      app = var.name
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = var.name
      }
    }
    template {
      metadata {
        labels = {
          app = var.name
        } 
      }
      spec {
        container {
          image = "${var.organization}/registry:${var.image_tag}"
          name  = "docker-registry"
          resources {
            limits {
              cpu    = "1.5"
              memory = "6Gi"
            }
            requests {
              cpu    = "1"
              memory = "4Gi"
            }
          }
          liveness_probe {
            exec {
              command = [
                "true"
              ]
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            success_threshold = 1
            timeout_seconds = 1
          }
          readiness_probe {
            exec {
              command = [
                "true"
              ]
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            success_threshold = 1
            timeout_seconds = 1
          }
          port {
            container_port = "5000"
            name           = "http"
          }
          port {
            name           = "http-metrics"
            container_port = "5001"
          }
          volume_mount {
            mount_path = var.mount_path
            name       = var.volume_name
          }
          dynamic "env" {
            for_each = local.env
            content {
              name  = env.value.name
              value = env.value.value
            }
          }
        }
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
                node_selector_term {
                    match_expressions {
                        key      = "kubernetes.io/role"
                        operator = "In"
                        values = [ var.node_selector ]
                      }
                  }
              }
          }
        }
        volume {
          persistent_volume_claim {
            claim_name = var.claim_name
          }
          name = var.volume_name
        }
        toleration {
          effect   = "NoSchedule"
          key      = "dedicated"
          operator = "Equal"
          value = var.node_selector
        }
        image_pull_secrets {
          name = "regcred"
        }
      }
    }
  }
}

resource "kubernetes_service" "docker-registry" {
  metadata {
    name = var.name
    namespace   = var.namespace
    labels = {
      app = var.name
    }
    annotations = {
      app = var.name
    }
  }
  spec {
    selector = {
      app = var.name
    }
    port {
      name = "http"
      node_port = "31159"
      port        = 5000
      target_port = "http"
    }
    port {
      name = "http-metrics"
      port        = 5001
      target_port = "5001"
    }
    type = "NodePort"
  }
}

# Ingress
resource "kubernetes_ingress" "docker-registry" {
  count = local.deploy_ingress == true ? 1 : 0
  depends_on = [kubernetes_service.docker-registry]
  metadata {
    name      = var.name
    namespace = var.namespace
    labels = {
      app = var.name
    }
    annotations = {
      "kubernetes.io/ingress.class"                       = "${var.ingress_class}",
      "nginx.ingress.kubernetes.io/proxy-connect-timeout" = "30",
      "nginx.ingress.kubernetes.io/proxy-send-timeout"    = "180",
      "nginx.ingress.kubernetes.io/proxy-read-timeout"    = "180"
    }
  }
  spec {
    rule {
      host = var.docker_registry_host
      http {
        path {
          backend {
            service_name = var.name
            service_port = "http"
          }
          path = "/"
        }
      }
    }
    tls {
      hosts       = ["*.${var.domain_name}.com"]
      secret_name = "${var.domain_name}.com"
    }
  }
}
