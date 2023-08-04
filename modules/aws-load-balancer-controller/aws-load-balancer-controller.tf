# data "aws_iam_policy" "alb-policy" {
#   name = var.alb_policy_name
# }

resource "aws_iam_policy" "alb-policy" {
  # count       = data.aws_iam_policy.alb-policy.name != null ? 0 : 1
  name        = var.alb_policy_name
  path        = "/"
  description = var.alb_policy_name
  policy = file("./iam_policy.json")
}

# https://registry.terraform.io/modules/Young-ook/eks/aws/1.4.5/submodules/iam-role-for-serviceaccount
# module "irsa" {
#   depends_on = [aws_iam_policy.alb-policy]
#   source  = "Young-ook/eks/aws//modules/iam-role-for-serviceaccount"

#   namespace  = "kube-system"
# #   name = "AmazonEKSLoadBalancerControllerRole"
#   serviceaccount = "aws-load-balancer-controller"
#   oidc_url       = var.cluster_oidc_issuer_url
#   oidc_arn       = var.oidc_provider_arn
#   policy_arns    = ["arn:aws:iam::${var.account_id}:policy/${var.alb_policy_name}"]
#   tags           = { "env" = "prod" }
# }

# data "aws_iam_openid_connect_provider" "eks" {
#   arn = "${var.oidc_provider_arn}"
# }

resource "aws_iam_role" "AmazonEKSLoadBalancerControllerRole" {
  name = "AmazonEKSLoadBalancerControllerRole"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${var.account_id}:oidc-provider/${var.oidc_provider}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${var.oidc_provider}:aud": "sts.amazonaws.com",
                    "${var.oidc_provider}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ]
}
EOF
  tags = {
    Environment = "Production"
  }
}

resource "aws_iam_role_policy_attachment" "AmazonEKSLoadBalancerController-attach" {
  role       = aws_iam_role.AmazonEKSLoadBalancerControllerRole.name
  policy_arn = aws_iam_policy.alb-policy.arn
}

resource "kubernetes_service_account" "alb" {
  depends_on = [aws_iam_role_policy_attachment.AmazonEKSLoadBalancerController-attach]
  metadata {
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${var.account_id}:role/AmazonEKSLoadBalancerControllerRole"
      # https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

# https://github.com/aws/eks-charts/tree/v0.0.101/stable/aws-load-balancer-controller/crds
resource "null_resource" "create_crd" {
  depends_on = [kubernetes_service_account.alb]
  provisioner "local-exec" {
    command = "kubectl apply -k 'github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=v0.0.101'"
  }
}

# kubectl patch ingress ingress-2048 -n game-2049 -p '{"metadata":{"finalizers":[]}}' --type=merge
# https://github.com/aws/eks-charts/tree/v0.0.101/stable/aws-load-balancer-controller
resource "helm_release" "aws-load-balancer-controller" {
  depends_on = [null_resource.create_crd]
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.5.5"
  wait       = "false"
  values = [<<EOF
clusterName: ${var.clusterName}
replicaCount: ${var.replicaCount}
vpcId: ${var.vpc_id}
region: "us-east-1"
serviceAccount:
  create: false
  name: aws-load-balancer-controller
EOF
  ]
}

# https://aws.amazon.com/premiumsupport/knowledge-center/eks-alb-ingress-controller-fargate/
