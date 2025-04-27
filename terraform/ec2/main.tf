terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.41.0"
    }
    ansible = {
      version = "~> 1.3.0"
      source  = "ansible/ansible"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

locals {
  config = yamldecode(file(var.config))
}

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Setup an EC2 instance for development
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Upload pub key to AWS, allowing me to use the same key for SSH conns
resource "aws_key_pair" "practice_server_key" {
  key_name   = "TestServerKey"
  public_key = file("~/.ssh/acg_practice.pub")
}

# Get my public IP for the instance's SG
data "external" "my_public_ip" {
  program = ["bash", "-c", "curl -s 'https://ipinfo.io/json'"]
}

# Allow all traffic from my IP address
resource "aws_security_group" "allow_all_from_my_ip" {
  name        = "allow_all_from_my_ip"
  description = "Allow all traffic from my IP address"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols, no trailing space
    cidr_blocks = [format("%s/32", data.external.my_public_ip.result["ip"])]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # All protocols, no trailing space
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name = "AllowAllTrafficFromMyIP"
  }
}

resource "aws_instance" "practice_ec2" {
  ami                    = "ami-0de8a7e805b017a1f" # Ubuntu 22.04
  instance_type          = "t3.medium"             # Max for ACG Labs
  key_name               = aws_key_pair.practice_server_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_all_from_my_ip.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  root_block_device {
    volume_size = "100" # Max for ACG Labs
  }

  metadata_options {
    http_tokens = "required" # Required for EC2 instance metadata service v2, AWS recommends this
  }

  tags = {
    Name = "PracticeEC2"
  }
}

# Create IAM Role for the instance
resource "aws_iam_role" "ec2_role" {
  name = "EC2"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Fetch the AWS account ID
data "aws_caller_identity" "current" {}

# Use the account ID to construct the policy ARNs, so I don't have to add my keys to the
# newly created EC2 instance. It automatically gets all permissions allowed. 
locals {
  allow_all_policy_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/allow_all"
  playground_policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/Playground_AWS_Sandbox"
}

# Attach the dynamically constructed policy ARNs to the Role. Need this because the ACG account number changes every time. 
resource "aws_iam_role_policy_attachment" "ec2_policy_attach_allow_all" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = local.allow_all_policy_arn
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attach_playground" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = local.playground_policy_arn
}

# Create Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.ec2_role.name
}

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Ansible Inventory
# REF: https://registry.terraform.io/providers/ansible/ansible/latest/docs
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Define the playbook to run
# REF: https://github.com/ansible/terraform-provider-ansible/blob/main/examples/ansible_playbook/simple.tf
resource "ansible_playbook" "playbook" {
  playbook = "playbook.yml"

  # Inventory configuration
  name   = aws_instance.practice_ec2.public_dns # name of the host to use for inventory configuration
  groups = ["learn"]                            # list of groups to add our host to

  # Play control
  # Configure our playbook execution, to run only tasks with specified tags.
  # in this example, we have only one tag; "tag1".
  # tags = [
  #   "tag1"
  # ]

  replayable = true

  # Connection configuration and other vars
  extra_vars = local.config.ansible.host

  verbosity = 3 # set the verbosity level of the debug output for this playbook
}

# Used to be able to use direct ansible commands with the inventory.yml file, which reads
# this output. 
resource "ansible_host" "practice_ec2" {
  name      = aws_instance.practice_ec2.public_dns
  groups    = ["practice_ec2"]
  variables = local.config.ansible.host
}

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Ansible Inventory
# REF: https://registry.terraform.io/providers/ansible/ansible/latest/docs
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
output "directions" {
  description = "Reminder to SSH into the instance"
  value = join("\n", [
    "Use the following command to SSH into your instance:",
    "ssh -i ~/.ssh/acg_practice ubuntu@${aws_instance.practice_ec2.public_dns}",
    "Subsequent ansible changes can be made using the ansible-playbook command:",
    "ansible-playbook -i inventory.yml playbook.yml",
  ])
}

