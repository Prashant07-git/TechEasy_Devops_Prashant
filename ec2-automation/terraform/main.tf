data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  default_for_az    = true
  availability_zone = data.aws_availability_zones.available.names[0]
}

data "aws_availability_zones" "available" {
  state = "available"
}

# ✅ Use existing Security Group instead of creating new
data "aws_security_group" "ec2_sg" {
  name = "${var.stage}-ec2-sg"
}

# ✅ Use existing IAM Role instead of creating new
data "aws_iam_role" "ec2_s3_role" {
  name = "${var.stage}-ec2-s3-role"
}

# ✅ Use existing Instance Profile instead of creating new
data "aws_iam_instance_profile" "s3_upload_profile" {
  name = "${var.stage}-s3-upload-profile"
}

resource "aws_s3_bucket" "app_logs" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_lifecycle_configuration" "log_expiry" {
  bucket = aws_s3_bucket.app_logs.id

  rule {
    id     = "DeleteOldLogs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 7
    }
  }
}

resource "aws_instance" "app_server" {
  ami                    = "ami-03f4878755434977f"
  instance_type          = "t2.micro"
  key_name               = "TechEasy3"
  subnet_id              = data.aws_subnet.default.id
  iam_instance_profile   = data.aws_iam_instance_profile.s3_upload_profile.name
  vpc_security_group_ids = [data.aws_security_group.ec2_sg.id]

  tags = {
    Name = "${var.stage}-Server"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y java-21-openjdk maven git

              cd /home/ec2-user
              git clone https://github.com/techeazy-consulting/techeazy-devops.git
              cd techeazy-devops

              mvn clean package -DskipTests

              nohup java -jar target/techeazy-devops-0.0.1-SNAPSHOT.jar --server.port=80 > /home/ec2-user/app.log 2>&1 &
              EOF
}
