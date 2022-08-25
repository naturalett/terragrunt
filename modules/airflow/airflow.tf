resource "helm_release" "airflow" {
  name       = "airflow"
  namespace  = "kube-system"
  repository = "https://airflow-helm.github.io/charts"
  chart      = "airflow"
  version    = "8.6.1"
  wait       = "false"
  values = [<<EOF
triggerer:
  enabled: false
flower:
  enabled: false
ingress:
  enabled: true
  web:
    host: "test.devops-workshop.com"
    ingressClassName: "nginx"
dags:
  persistence:
    accessMode: "ReadWriteMany"
    enabled: "${var.existing_claim_enabled}"
    existingClaim: "${var.existing_claim}"
EOF
  ]
}
