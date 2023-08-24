# Ingress
resource "kubernetes_ingress" "docker-registry" {
  metadata {
    name      = "docker-registry"
    labels = {
      "app.kubernetes.io/name" = "docker-registry",
      "app" =  "docker-registry",
      "chart" =  "docker-registry-2.2.2",
      "release" =  "docker-registry",
      "heritage" =  "Helm"
    }
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class"                       = "${var.ingress_class}",
      "nginx.ingress.kubernetes.io/proxy-connect-timeout" = "30",
      "nginx.ingress.kubernetes.io/proxy-send-timeout"    = "180",
      "nginx.ingress.kubernetes.io/proxy-read-timeout"    = "180"
      "meta.helm.sh/release-name" = "docker-registry"
      "meta.helm.sh/release-namespace" = var.namespace
    }
  }
  spec {
    rule {
      host = "${var.docker_registry_host}"
      http {
        path {
          backend {
            service_name = "docker-registry"
            service_port = "5000"
          }
          path = "/"
        }
      }
    }
    tls {
      hosts       = ["*.${var.domain_name}.com"]
    }
  }
}
