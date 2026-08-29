output "instance_id" {
  value = aws_instance.this.id
}

output "instance_arn" {
  value = aws_instance.this.arn
}

output "runtime_role_arn" {
  value = aws_iam_role.runtime.arn
}

output "public_ipv4" {
  value = aws_eip.this.public_ip
}
