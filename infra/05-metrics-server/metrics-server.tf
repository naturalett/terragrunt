resource "helm_release" "metrics-server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = "3.8.2"
  wait       = "false"
  values = [<<EOF
EOF
  ]
}
