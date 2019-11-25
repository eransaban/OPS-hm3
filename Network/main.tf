##################################################################################
# Remote State
##################################################################################
terraform {
  backend "s3" {
    bucket = "eran-tfbucket"
    key    = "hm-networktf.tfstate"
    region = "us-east-1"
  }
}



##################################################################################
# VARIABLES
##################################################################################

variable "private_key_path" {}
variable "key_name" {}
variable "region" {
  default = "us-east-1"
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {

  region     = var.region
  }

##################################################################################
# DATA
##################################################################################


##################################################################################
# Modules
##################################################################################


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "hm-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.100.0/24", "10.0.200.0/24"]
  public_subnets  = ["10.0.10.0/24", "10.0.20.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  single_nat_gateway = true
  one_nat_gateway_per_az = false

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}


module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name = "my-alb"
  enable_deletion_protection	= false

  load_balancer_type = "application"

  vpc_id             = module.vpc.vpc_id
  subnets            = ["${module.vpc.public_subnets[0]}","${module.vpc.public_subnets[1]}"]
  security_groups    = [aws_security_group.ELB_Security_Group.id]

  target_groups = [
    {
      name      = "lb-targetgroup"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      stickiness = {
        type = "lb_cookie",
        cookie_duration = 60
        enabled = true
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "App LB"
  }
}

resource "aws_lb_listener_rule" "forward" {
  listener_arn = "${module.alb.http_tcp_listener_arns[0]}"
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = "${module.alb.target_group_arns[0]}"
  }

    condition {
    field  = "path-pattern"
    values = ["/static/*"]
  }
}

##################################################################################
# SecurityGRoups
##################################################################################

resource "aws_security_group" "public_Security_group" {
  name        = "Public_Security_Group"
  description = "Allow ssh and internet for webservers"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["84.228.79.224/32"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "Private_Security_Group" {
  name        = "Private_Security_Group"
  description = "private to internet"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.10.0/24", "10.0.20.0/24"]
  }
  
    ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["10.0.10.0/24", "10.0.20.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ELB_Security_Group" {
  name        = "ELB_Security_Group"
  description = "access to webservers"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
