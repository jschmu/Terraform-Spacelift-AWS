resource "aws_vpc" "tsa_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "tsa_public_subnet" {
  vpc_id                  = aws_vpc.tsa_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1a"

  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "tsa_internet_gateway" {
  vpc_id = aws_vpc.tsa_vpc.id

  tags = {
    Name = "tsa_igw"
  }
}

resource "aws_route_table" "tsa_public_rt" {
  vpc_id = aws_vpc.tsa_vpc.id

  tags = {
    Name = "dev_public_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.tsa_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tsa_internet_gateway.id
}

resource "aws_route_table_association" "tsa_public_assoc" {
  subnet_id      = aws_subnet.tsa_public_subnet.id
  route_table_id = aws_route_table.tsa_public_rt.id
}

resource "aws_security_group" "tsa_sg" {
  name        = "dev_sg"
  description = "security group for dev"
  vpc_id      = aws_vpc.tsa_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #Open to all IPs - for development/testing only!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}