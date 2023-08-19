resource "kubernetes_role" "kubeDashMinimal" {
  metadata {
    name      = "kubernetes-dashboard-minimal"
    namespace = "kube-system"
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create"]
  }
  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create"]
  }
  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = ["kubernetes-dashboard-key-holder", "kubernetes-dashboard"]
    verbs          = ["get", "update", "delete"]
  }
  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = ["kubernetes-dashboard-csrf"]
    verbs          = ["get", "update"]
  }
  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["kubernetes-dashboard-settings"]
    verbs          = ["get", "update"]
  }
  rule {
    api_groups     = [""]
    resources      = ["services"]
    resource_names = ["heapster"]
    verbs          = ["proxy"]
  }
  rule {
    api_groups     = [""]
    resources      = ["services/proxy"]
    resource_names = ["heapster", "http:heapster:", "https:heapster:"]
    verbs          = ["get"]
  }
  rule {
    api_groups = ["", "extensions", "apps", "batch"]
    resources  = ["secrets", "configmaps", "deployments"]
    verbs      = ["get", "list", "update", "patch", "delete"]
  }
}

resource "kubernetes_role_binding" "kubeDashMinimal" {
  metadata {
    name      = "kubernetes-dashboard-minimal"
    namespace = "kube-system"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.kubeDashMinimal.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = "kubernetes-dashboard"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "dashViewer" {
  metadata {
    name = "dashboard-viewer-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "view"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "kubernetes-dashboard"
    namespace = "kube-system"
  }
}

data "kubernetes_service" "ingress_nginx" {
  metadata {
    namespace = "kube-system"
    name = "ingress-nginx-controller"
    labels = {
      nginx = "internet-facing"
    }
  }
}

# https://github.com/kubernetes/dashboard/blob/v2.5.0/aio/deploy/helm-chart/kubernetes-dashboard/Chart.yaml
resource "helm_release" "kubernetes-dashboard" {
  name       = "kubernetes-dashboard"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/dashboard/"
  chart      = "kubernetes-dashboard"
  version    = "5.1.3"
  wait       = "false"
  values = [<<EOF

extraArgs:
  - --enable-skip-login
  - --enable-insecure-login
  - --system-banner="Welcome to Kubernetes"
  - --disable-settings-authorizer
metrics-server:
  enabled: false
metricsScraper:
  enabled: true
rbac:
  create: false
serviceAccount:
  name: "kubernetes-dashboard"
ingress:
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/configuration-snippet: |
      rewrite ^(/dashboard)$ $1/ redirect;
  hosts: ["${data.kubernetes_service.ingress_nginx.status.0.load_balancer.0.ingress.0.hostname}"]
  tls: []
  customPaths:
    - backend:
        service:
          name: kubernetes-dashboard
          port:
            number: 443
      path: /dashboard(/|$)(.*)
      pathType: Prefix
  enabled: ${var.ingress_enabled}
  className: nginx
EOF
  ]
}
