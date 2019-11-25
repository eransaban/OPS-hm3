##################################################################################
# DATA
##################################################################################

data "aws_ami" "aws-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "selected" {
  default = false
  cidr_block = "10.0.0.0/16"
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.selected.id
}

data "aws_subnet" "private1a" {
  vpc_id = data.aws_vpc.selected.id
  cidr_block = "10.0.100.0/24"  
 
  }


data "aws_subnet" "private1b" {
  vpc_id = data.aws_vpc.selected.id
  cidr_block = "10.0.200.0/24"  
  }

data "aws_subnet" "public1a" {
  vpc_id = data.aws_vpc.selected.id
  cidr_block = "10.0.10.0/24"  
}
data "aws_subnet" "public1b" {
  vpc_id = data.aws_vpc.selected.id
  cidr_block = "10.0.20.0/24"  

}
data "aws_lb_target_group" "lb-targetgroup" {
    name = "lb-targetgroup"
}

data "aws_security_group" "public" {
  vpc_id = data.aws_vpc.selected.id
  name = "Public_Security_Group"
}

data "aws_security_group" "private" {
  vpc_id = data.aws_vpc.selected.id
  name = "Private_Security_Group"
}

data "aws_security_group" "ALB" {
  vpc_id = data.aws_vpc.selected.id
  name = "ELB_Security_Group"
}


data "aws_lb_target_group" "targetgroup" {
    name = "lb-targetgroup"
}

data "aws_lb" "app-lb" {
  name = "my-alb"
}