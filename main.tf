#
provider "aws" {
  region = "us-east-1"
}

# יצירת Security Group לאפשר גישה ב-HTTP
resource "aws_security_group" "apache_sg" {
  name        = "allow_http"
  description = "Allow HTTP traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# יצירת EC2 instance
resource "aws_instance" "apache_server" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI
  instance_type = "t2.micro"

  security_groups = [aws_security_group.apache_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install httpd -y
              systemctl start httpd
              systemctl enable httpd
              echo "Hello, Apache is running on AWS!" > /var/www/html/index.html
            EOF

  tags = {
    Name = "Apache-Server"
  }
}

# הצגת הפלט של כתובת ה-IP הציבורית
output "public_ip" {
  value = aws_instance.apache_server.public_ip
}

# Write public IP to a file using a local-exec provisioner
resource "null_resource" "write_ip" {
  provisioner "local-exec" {
    command = "echo \"${aws_instance.apache_server.public_ip}\" > public_ip.txt"
  }

  depends_on = [aws_instance.apache_server]
}
