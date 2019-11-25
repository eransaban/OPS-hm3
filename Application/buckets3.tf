resource "aws_iam_role" "s3_role" {
  name = "s3_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
      tag-key = "S3 iam-Role"
  }
}
resource "aws_iam_instance_profile" "iam_s3_profile" {
  name = "s3_profile"
  role = "${aws_iam_role.s3_role.name}"
}

resource "aws_iam_role_policy" "s3_allow_policy" {
  name = "s3_Allow_policy"
  role = "${aws_iam_role.s3_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_s3_bucket" "eran-nginx-logs" {
  bucket = "eran-tf-nginx-bucket"
  acl    = "private"
  force_destroy = true

  tags = {
    Name        = "Nginx Log"
    }
}

