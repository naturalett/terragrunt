output "efsVolume_id" {
  description = "EFS ID"
  value = "${aws_efs_file_system.efsVolume.id}"
}

output "aws_iam_policy_arn" {
  value = data.aws_iam_policy.efs-policy.arn
}