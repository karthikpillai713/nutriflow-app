resource "aws_vpc" "nutriflow" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "nutriflow-vpc"
  }
}

resource "aws_internet_gateway" "nutriflow" {
  vpc_id = aws_vpc.nutriflow.id

  tags = {
    Name = "nutriflow-igw"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.nutriflow.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "nutriflow-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.nutriflow.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "nutriflow-public-b"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.nutriflow.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nutriflow.id
  }

  tags = {
    Name = "nutriflow-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}
