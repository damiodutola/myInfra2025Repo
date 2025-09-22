provider "aws" {
  region = var.aws_region
}

# ---------------------------
# VPC
# ---------------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = merge(
    var.tags,
    {
      Name        = "main-vpc-${var.environment}"
      Environment = var.environment
    }
  )
}

# ---------------------------
# Subnet
# ---------------------------
resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = merge(
    var.tags,
    {
      Name        = "main-subnet-${var.environment}"
      Environment = var.environment
    }
  )
}

# ---------------------------
# Internet Gateway
# ---------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name        = "igw-${var.environment}"
      Environment = var.environment
    }
  )
}

# ---------------------------
# Route Table
# ---------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.tags,
    {
      Name        = "public-rt-${var.environment}"
      Environment = var.environment
    }
  )
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------
# Security Group (with lifecycle fix)
# ---------------------------
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg-${var.environment}"
  description = "Security group for Jenkins in ${var.environment}"
  vpc_id      = aws_vpc.main.id

  # Ensure new SG is created before old one is destroyed
  lifecycle {
    create_before_destroy = true
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Jenkins Web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "jenkins-sg-${var.environment}"
      Environment = var.environment
    }
  )
}

# ---------------------------
# EC2 Instance
# ---------------------------
resource "aws_instance" "myFirstInstance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = aws_subnet.main.id

  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  tags = merge(
    var.tags,
    {
      Name        = "${var.tag_name}-${var.environment}"
      Environment = var.environment
    }
  )
}

# ---------------------------
# Elastic IP (only for prod)
# ---------------------------
resource "aws_eip_association" "myElasticIP_assoc" {
  count         = var.environment == "prod" ? 1 : 0
  instance_id   = aws_instance.myFirstInstance.id
  allocation_id = var.allocation_id
}

# ---------------------------
# Outputs
# ---------------------------
output "instance_id" {
  value = aws_instance.myFirstInstance.id
}

output "instance_public_ip" {
  value = aws_instance.myFirstInstance.public_ip
}

