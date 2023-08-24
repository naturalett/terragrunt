# https://github.com/kubernetes/ingress-nginx/blob/helm-chart-4.2.3/charts/ingress-nginx/Chart.yaml
resource "helm_release" "ingress-nginx" {
  name = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart = "ingress-nginx"
  namespace = "kube-system"
  version = "4.2.3"
  timeout = 300

  values = [
    "${file("./values.yaml")}"
  ]

  set {
    name  = "cluster.enabled"
    value = "true"
  }

  set {
    name  = "metrics.enabled"
    value = "true"
  }
}