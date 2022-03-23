module "ami_helper" {
  source = "recarnot/ami-helper/aws"
  os     = module.ami_helper.AMAZON_LINUX_2
}


data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_region" "current" {
}

locals {
  region       = replace(data.aws_region.current.name, "-", "")
  name_postfix = "${local.region}-${var.name_postfix}"
}
resource "random_string" "admin_password" {
  length  = 32
  special = false
}

resource "random_string" "secret_cookie" {
  length  = 64
  special = false
}

data "aws_iam_policy_document" "policy_doc" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "template_file" "cloud-init" {
  template = file("${path.module}/cloud-init.yaml")

  vars = {
    admin_password     = random_string.admin_password.result
    secret_cookie      = random_string.secret_cookie.result
    access_key         = aws_iam_access_key.rabbit_user.id
    secret             = aws_iam_access_key.rabbit_user.secret
    private_key        = "${jsonencode(var.git_key)}"
    ansible_git_url    = var.ansible_git_url
    ansible_git_branch = var.ansible_git_branch
    ansible_playbook   = var.ansible_playbook
  }
}

resource "aws_iam_user" "rabbit_user" {
  name = "${var.name_prefix}-usr-${local.name_postfix}"
  tags = {
    service = var.service_tag
  }
}

resource "aws_iam_access_key" "rabbit_user" {
  user = aws_iam_user.rabbit_user.name
}

resource "aws_iam_user_policy" "rabbit_user" {
  name = "${var.name_prefix}-iup-${local.name_postfix}"
  user = aws_iam_user.rabbit_user.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:DescribeAutoScalingInstances",
        "ec2:DescribeInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF


}
resource "aws_iam_role" "role" {
  name               = "${var.name_prefix}-irl-${local.name_postfix}"
  assume_role_policy = data.aws_iam_policy_document.policy_doc.json
}

resource "aws_iam_role_policy" "policy" {
  name = "${var.name_prefix}-irp-${local.name_postfix}"
  role = aws_iam_role.role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingInstances",
                "ec2:DescribeInstances"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF

}

resource "aws_iam_instance_profile" "profile" {
  name_prefix = "${var.name_prefix}-iip-${local.name_postfix}"
  role        = aws_iam_role.role.name
}

resource "aws_security_group" "rabbitmq_elb" {
  name        = "${var.name_prefix}-elb-${local.name_postfix}"
  vpc_id      = var.vpc_id
  description = "Security Group for the rabbitmq elb"

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.name_prefix}-elb-${local.name_postfix}"
    service = var.service_tag
  }
}

resource "aws_security_group" "rabbitmq_nodes" {
  name        = "${var.name_prefix}-scg-${local.name_postfix}"
  vpc_id      = var.vpc_id
  description = "Security Group for the rabbitmq nodes"

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    self      = true
  }

  ingress {
    protocol    = "tcp"
    from_port   = 5672
    to_port     = 5672
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 15672
    to_port     = 15672
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = {
    Name    = "${var.name_prefix}-scg-${local.name_postfix}",
    service = var.service_tag
  }
}

resource "aws_launch_configuration" "rabbitmq" {
  name_prefix          = "${var.name_prefix}-lcf-${local.name_postfix}"
  image_id             = module.ami_helper.ami_id
  instance_type        = var.instance_type
  key_name             = var.ssh_key_name
  security_groups      = concat([aws_security_group.rabbitmq_nodes.id], var.nodes_additional_security_group_ids)
  iam_instance_profile = aws_iam_instance_profile.profile.id
  user_data            = data.template_file.cloud-init.rendered

  root_block_device {
    volume_type           = var.instance_volume_type
    volume_size           = var.instance_volume_size
    iops                  = var.instance_volume_iops
    throughput            = var.instance_volume_throughput
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "rabbitmq" {
  name                      = "${var.name_prefix}-asg-${local.name_postfix}"
  min_size                  = var.size
  desired_capacity          = var.size
  max_size                  = var.size
  health_check_grace_period = 600
  health_check_type         = "ELB"
  force_delete              = true
  launch_configuration      = aws_launch_configuration.rabbitmq.name
  load_balancers            = [aws_elb.elb.name]
  vpc_zone_identifier       = var.subnet_ids

  tags = [
    {
      key                 = "Name"
      value               = "${var.name_prefix}-asg-${local.name_postfix}"
      propagate_at_launch = true
    },
    {
      key                 = "service"
      value               = var.service_tag
      propagate_at_launch = true
    }
  ]
}

resource "aws_elb" "elb" {
  name = "${var.name_prefix}-elb-${local.name_postfix}"

  listener {
    instance_port     = 5672
    instance_protocol = "tcp"
    lb_port           = 5672
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 15672
    instance_protocol = "tcp"
    lb_port           = 15672
    lb_protocol       = "tcp"
  }

  health_check {
    interval            = 30
    unhealthy_threshold = 10
    healthy_threshold   = 2
    timeout             = 3
    target              = "TCP:5672"
  }

  subnets         = var.subnet_ids
  idle_timeout    = 3600
  internal        = true
  security_groups = concat([aws_security_group.rabbitmq_elb.id], var.elb_additional_security_group_ids)

  tags = {
    Name    = "${var.name_prefix}-elb-${local.name_postfix}"
    service = var.service_tag
  }
}
