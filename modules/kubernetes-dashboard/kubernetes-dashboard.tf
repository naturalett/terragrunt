resource "helm_release" "kubernetes-dashboard" {
  name       = "kubernetes-dashboard"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/dashboard/"
  chart      = "kubernetes-dashboard"
  version    = "5.9.0"
  wait       = "false"
  values = [<<EOF
extraArgs:
  - --enable-skip-login
  - --enable-insecure-login
service:
  type: NodePort
  externalPort: 80
ingress:
  enabled: ${var.ingress_enabled}
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/group.name: ${var.group_name}
EOF
  ]
}
