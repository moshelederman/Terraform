terraform {
  backend "s3" {
    bucket         = "moshe-terrarorm"
    key            = "terraform/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"  # שנה לאזור שלך
}

resource "aws_instance" "docker_instance" {
  ami           = "ami-0df8c184d5f6ae949" # Amazon Linux 2 AMI
  instance_type = "t2.micro"

  tags = {
    Name = "docker-compose-instance"
  }

  # מפתח SSH להתחברות
  key_name = "moshe-key"  # שנה לשם מפתח ה-SSH שלך

  # גישה למכונה דרך הפורטים המתאימים
  security_groups = [aws_security_group.docker_sg.name]
user_data = <<-EOF
    #!/bin/bash
    set -e
    sudo yum update -y
    sudo yum install -y libxcrypt-compat
    sudo yum install -y git
    sudo yum install -y docker
    sudo systemctl start docker 
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user
    newgrp docker

    # התקנת Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # שיבוט הפרויקט מ-GitHub
    cd /home/ec2-user
    git clone https://github.com/moshelederman/DevOps-Project.git

    # יצירת קובץ .env עם משתנים
    echo "MYSQL_ROOT_PASSWORD=${var.mysql_root_password}" > /home/ec2-user/DevOps-Project/project/.env
    echo "MYSQL_DATABASE=${var.mysql_database}" >> /home/ec2-user/DevOps-Project/project/.env
    echo "MYSQL_USER=${var.mysql_user}" >> /home/ec2-user/DevOps-Project/project/.env
    echo "MYSQL_PASSWORD=${var.mysql_password}" >> /home/ec2-user/DevOps-Project/project/.env
    echo "MYSQL_HOST=${var.mysql_host}" >> /home/ec2-user/DevOps-Project/project/.env
    
    # מעבר לתיקייה והרצת Docker Compose
    cd /home/ec2-user/DevOps-Project
    cd project
    docker-compose up -d  
    EOF
}

resource "aws_security_group" "docker_sg" {
  name        = "docker-sg"
  description = "Allow access to Docker container"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
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
