# https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html
# https://github.com/kubernetes-sigs/aws-efs-csi-driver/tree/master/charts/aws-efs-csi-driver

data "aws_iam_policy" "efs-policy" {
  name = "AmazonEKS_EFS_CSI_Driver_Policy"
}

resource "aws_iam_policy" "efs-policy" {
  count       = data.aws_iam_policy.efs-policy.name != null ? 0 : 1
  name        = var.efs_policy_name
  path        = "/"
  description = var.efs_policy_name
  policy = file("./iam-policy-efs.json")
}

module "irsa" {
  depends_on = [aws_iam_policy.efs-policy]
  source  = "Young-ook/eks/aws//modules/iam-role-for-serviceaccount"

  namespace  = "kube-system"
  serviceaccount = "efs-csi-controller-sa"
  oidc_url       = var.cluster_oidc_issuer_url
  oidc_arn       = var.oidc_provider_arn
  policy_arns    = ["arn:aws:iam::${var.account_id}:policy/AmazonEKS_EFS_CSI_Driver_Policy"]
  tags           = { "env" = "prod" }
}

resource "helm_release" "aws-efs-csi-driver" {
  depends_on = [module.irsa]
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
    create: true
    name: efs-csi-controller-sa
    annotations:
      eks.amazonaws.com/role-arn: ${module.irsa.arn}
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

data "aws_subnet_ids" "destination" {
  vpc_id = var.vpc_id
  tags = {
    Tier = "Private"
  }
}

resource "aws_efs_mount_target" "efsMounts" {
  depends_on = [aws_efs_file_system.efsVolume]
  for_each        = data.aws_subnet_ids.destination.ids
  file_system_id  = aws_efs_file_system.efsVolume.id
  subnet_id       = each.value
  security_groups = [var.node_security_group_id]
}

resource "kubernetes_storage_class" "aws-efs-csi-driver-storage" {
  depends_on = [aws_efs_mount_target.efsMounts]
  metadata {
    name = var.efs_name
  }
  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Retain"
  parameters = {
    type = "pd-standard"
  }
}
