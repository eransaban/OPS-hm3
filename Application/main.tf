##################################################################################
# S3 Backend
##################################################################################
terraform {
  backend "s3" {
    bucket = "eran-tfbucket"
    key    = "hm-apptf.tfstate"
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

variable "lb_tg_arn" {
  type    = "string"
  default = ""
}

variable "lb_tg_name" {
  type    = "string"
  default = ""
}

#variable "security_group_id" {}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {

  region     = var.region
  }


##################################################################################
# Ec2 Instance
##################################################################################


resource "aws_instance" "webserver-1a" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [data.aws_security_group.public.id]
  iam_instance_profile = "${aws_iam_instance_profile.iam_s3_profile.name}"
  availability_zone = "us-east-1a"
  associate_public_ip_address = true
  subnet_id = data.aws_subnet.public1a.id
  
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)

  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum --enablerepo epel-testing install s3cmd -y",
      "s3cmd get s3://eran-tfbucket/script.sh /home/ec2-user/script.sh",
      "sudo chmod 700 /home/ec2-user/script.sh",
      "sudo cp /home/ec2-user/script.sh /etc/cron.hourly/script.sh",
      "sudo yum install nginx -y",
      "sudo service nginx start",
      "echo '<html><head><title>OpsSchool Server 1 !!!</title></head><body style=\"background-color:#0F00F0\"><p style=\"text-align: center;\"><span style=\"color:#FF00FF;\"><span style=\"font-size:28px;\">OpsSchool Server 1 !!!</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html",
      "sudo run-parts /etc/cron.hourly"
    ]
  }
  tags = {
    Name = "WebServer 1a"
    Owner = "Eran Saban"
    Purpose = "Server 1 in ALB"
  }
}
resource "aws_instance" "Webserver-1b" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [data.aws_security_group.public.id]
  iam_instance_profile = "${aws_iam_instance_profile.iam_s3_profile.name}"
  subnet_id = data.aws_subnet.public1b.id
  availability_zone = "us-east-1b"
  associate_public_ip_address = true

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)

  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum --enablerepo epel-testing install s3cmd -y",
      "s3cmd get s3://eran-tfbucket/script.sh /home/ec2-user/script.sh",
      "sudo chmod 700 /home/ec2-user/script.sh",
      "sudo cp /home/ec2-user/script.sh /etc/cron.hourly/script.sh",
      "sudo yum install nginx -y",
      "sudo service nginx start",

      "echo '<html><head><title>OpsSchool Server 2 !!!</title></head><body style=\"background-color:#FF0000\"><p style=\"text-align: center;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:28px;\">OpsSchool Server 2 !!!</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html",
      "sudo run-parts /etc/cron.hourly"
    ]
  }
  tags = {
    Name = "WebServer 1b"
    Owner = "Eran Saban"
    Purpose = "Server 2 in ALB"
  }
}

resource "aws_instance" "db-1a" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [data.aws_security_group.private.id]
  availability_zone = "us-east-1a"
  subnet_id = data.aws_subnet.private1a.id

  

  tags = {
    Name = "DB Server 1 "
    Owner = "Eran Saban"
    Purpose = "DB1 for WEB Backend"
  }

}
resource "aws_instance" "db-1b" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [data.aws_security_group.private.id]
  availability_zone = "us-east-1b"
  subnet_id = data.aws_subnet.private1b.id

  
  tags = {
    Name = "DB Server 2 "
    Owner = "Eran Saban"
    Purpose = "DB2 for WEB Backend"
  }
}

##################################################################################
# Attach To ALB
##################################################################################
resource "aws_lb_target_group_attachment" "attach-web1" {
  target_group_arn = "${data.aws_lb_target_group.targetgroup.arn}"
  target_id        = "${aws_instance.webserver-1a.id}"
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach-web2" {
  target_group_arn = "${data.aws_lb_target_group.targetgroup.arn}"
  target_id        = "${aws_instance.Webserver-1b.id}"
  port             = 80
}


##################################################################################
# OUTPUT
##################################################################################

output "aws_instance__web1_public_IP" {
  value = aws_instance.webserver-1a.public_ip
  }

output "aws_instance_web2_public_IP" {
  value = aws_instance.Webserver-1b.public_ip
  }
output "app_lb_public_ip" {
  value = data.aws_lb.app-lb.dns_name
  }

output "aws_instance_db1_private_IP" {
  value = aws_instance.db-1a.private_ip
  }

  output "aws_instance_db2_private_IP" {
  value = aws_instance.db-1b.private_ip
  }
