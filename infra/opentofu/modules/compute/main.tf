data "aws_ssm_parameter" "ami" {
  name = var.ami_ssm_parameter_name
}

data "aws_iam_policy_document" "instance_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "runtime" {
  name               = "${var.name_prefix}-runtime"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role.json

  tags = merge(var.tags, { Name = "${var.name_prefix}-runtime" })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.runtime.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "runtime" {
  statement {
    sid       = "EcrAuthorization"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "PullApplicationImages"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = var.ecr_repository_arns
  }

  statement {
    sid = "ListRuntimeBuckets"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = [
      var.media_bucket_arn,
      var.deployment_bucket_arn,
    ]
  }

  statement {
    sid = "ManageMediaObjects"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${var.media_bucket_arn}/*"]
  }

  statement {
    sid       = "ReadDeploymentArtifacts"
    actions   = ["s3:GetObject"]
    resources = ["${var.deployment_bucket_arn}/*"]
  }

  statement {
    sid = "ReadOriginCertificateParameters"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter${var.origin_certificate_parameter_name}",
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter${var.origin_private_key_parameter_name}",
    ]
  }
}

resource "aws_iam_role_policy" "runtime" {
  name   = "${var.name_prefix}-runtime"
  role   = aws_iam_role.runtime.id
  policy = data.aws_iam_policy_document.runtime.json
}

resource "aws_iam_instance_profile" "runtime" {
  name = "${var.name_prefix}-runtime"
  role = aws_iam_role.runtime.name

  tags = merge(var.tags, { Name = "${var.name_prefix}-runtime" })
}

resource "aws_instance" "this" {
  ami                         = data.aws_ssm_parameter.ami.value
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.runtime.name
  monitoring                  = true

  credit_specification {
    cpu_credits = "standard"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
  }

  user_data = templatefile("${path.module}/user-data.sh.tftpl", {})

  tags = merge(var.tags, { Name = "${var.name_prefix}-host" })
}

resource "aws_eip" "this" {
  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.name_prefix}-origin" })
}

resource "aws_eip_association" "this" {
  allocation_id = aws_eip.this.id
  instance_id   = aws_instance.this.id
}
