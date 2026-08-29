variable "name_prefix" {
  description = "Prefix applied to ECR repositories."
  type        = string
}

variable "repository_names" {
  description = "Logical application image repositories to create."
  type        = set(string)
}

variable "tags" {
  description = "Tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
