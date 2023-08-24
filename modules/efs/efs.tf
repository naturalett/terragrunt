# https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html
# https://github.com/kubernetes-sigs/aws-efs-csi-driver/tree/master/charts/aws-efs-csi-driver

# data "aws_iam_policy" "efs-policy" {
#   name = "AmazonEKS_EFS_CSI_Driver_Policy"
# }

resource "random_string" "random" {
  length           = 4
  special          = false
  lower  = true
}

resource "aws_iam_policy" "efs-policy" {
  # count       = data.aws_iam_policy.efs-policy.name != null ? 0 : 1
  name        = "${var.efs_policy_name}-${random_string.random.id}"
  path        = "/"
  description = "${var.efs_policy_name}-${random_string.random.id}"
  policy = file("./iam-policy-efs.json")
}

# module "irsa" {
#   depends_on = [aws_iam_policy.efs-policy]
#   source  = "Young-ook/eks/aws//modules/iam-role-for-serviceaccount"

#   namespace  = "kube-system"
#   serviceaccount = "efs-csi-controller-sa"
#   oidc_url       = var.cluster_oidc_issuer_url
#   oidc_arn       = var.oidc_provider_arn
#   policy_arns    = ["arn:aws:iam::${var.account_id}:policy/AmazonEKS_EFS_CSI_Driver_Policy"]
#   tags           = { "env" = "prod" }
# }

resource "aws_iam_role" "AmazonEKS_EFS_CSI_DriverRole" {
  name = "AmazonEKS_EFS_CSI_DriverRole-${random_string.random.id}"
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
                    "${var.oidc_provider}:sub": "system:serviceaccount:kube-system:efs-csi-controller-sa"
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

resource "aws_iam_role_policy_attachment" "AmazonEKS_EFS_CSI_Driver-attach" {
  role       = aws_iam_role.AmazonEKS_EFS_CSI_DriverRole.name
  policy_arn = aws_iam_policy.efs-policy.arn
}

resource "kubernetes_service_account" "efs" {
  depends_on = [aws_iam_role_policy_attachment.AmazonEKS_EFS_CSI_Driver-attach]
  metadata {
    name = "efs-csi-controller-sa"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "efs-csi-controller-sa"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${var.account_id}:role/AmazonEKS_EFS_CSI_DriverRole-${random_string.random.id}"
      # https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

resource "helm_release" "aws-efs-csi-driver" {
  depends_on = [aws_efs_file_system.efsVolume]
  name       = "aws-efs-csi-driver"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart      = "aws-efs-csi-driver"
  version    = "2.2.6"
  wait       = "false"
  values = [<<EOF
replicaCount: ${var.replicaCount}
controller:
  serviceAccount:
    create: false
    name: efs-csi-controller-sa
storageClasses:
- name: efs-sc
  mountOptions:
  - tls
  parameters:
    provisioningMode: "efs-ap"
    fileSystemId: "${aws_efs_file_system.efsVolume.id}"
    directoryPerms: "700"
EOF
  ]
}

resource "aws_security_group_rule" "authorize-security-group-ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_block]
  security_group_id = var.node_security_group_id
}

resource "aws_efs_file_system" "efsVolume" {
  creation_token = var.efs_name

  tags = {
    Name = var.efs_name
  }
}

data "aws_subnets" "destination" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  tags = {
    Tier = "Private"
  }
}

resource "aws_efs_mount_target" "efsMounts" {
  depends_on = [aws_efs_file_system.efsVolume]
  for_each        = toset(data.aws_subnets.destination.ids)
  file_system_id  = aws_efs_file_system.efsVolume.id
  subnet_id       = each.value
  security_groups = [var.node_security_group_id]
}
