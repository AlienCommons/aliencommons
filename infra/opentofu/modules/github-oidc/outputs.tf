output "infrastructure_role_arn" {
  value = aws_iam_role.infrastructure.arn
}

output "deploy_role_arn" {
  value = aws_iam_role.deploy.arn
}
