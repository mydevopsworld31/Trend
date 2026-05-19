provider "aws" {
  region = "ap-south-1"
}

# ---------------- VPC ----------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "devops-vpc"
  }
}

# ---------------- SUBNET ----------------
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# ---------------- INTERNET GATEWAY ----------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "devops-igw"
  }
}

# ---------------- ROUTE TABLE ----------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# ---------------- ROUTE TABLE ASSOCIATION ----------------
resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ---------------- SECURITY GROUP ----------------
resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
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

# ---------------- IAM ROLE ----------------
resource "aws_iam_role" "ec2_role" {
  name = "ec2-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach policy (for basic AWS access)
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# Instance profile
resource "aws_iam_instance_profile" "profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# ---------------- AMI ----------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }
}

# ---------------- EC2 ----------------
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.small"
  key_name               = "myjenkins"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  iam_instance_profile = aws_iam_instance_profile.profile.name

  tags = {
    Name = "Jenkins-Server"
  }
}
