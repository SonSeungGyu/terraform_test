provider "aws" {
  region = "ap-southeast-1"
  default_tags {
    tags = {
      Name = "student950705-practice4"
      Subject = "cloud-programming"
    }
  }
}


variable "vpc_main_cidr" {
  default = "10.0.0.0/23"
}

resource "aws_vpc" "vpc-950705" {
  cidr_block = var.vpc_main_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id = aws_vpc.vpc-950705.id
  cidr_block = "10.1.0.0/23"
}


resource "aws_subnet" "pub_sub_1" {
  vpc_id = aws_vpc.vpc-950705.id
  cidr_block = cidrsubnet(aws_vpc.vpc-950705.cidr_block, 1, 0)
  availability_zone = "ap-southeast-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "pri_sub_1" {
  vpc_id = aws_vpc.vpc-950705.id
  cidr_block = cidrsubnet(aws_vpc.vpc-950705.cidr_block, 1, 1)
  availability_zone = "ap-southeast-1a"
}

resource "aws_subnet" "pub_sub_2" {
  vpc_id = aws_vpc.vpc-950705.id
  cidr_block = cidrsubnet(aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block, 1, 0)
  availability_zone = "ap-southeast-1b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "pri_sub_2" {
  vpc_id = aws_vpc.vpc-950705.id
  cidr_block = cidrsubnet(aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block, 1, 1)
  availability_zone = "ap-southeast-1b"
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.vpc-950705.id
}

resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.vpc-950705.id
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table" "pri_rt1" {
  vpc_id = aws_vpc.vpc-950705.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_1.id
  }
}

resource "aws_route_table" "pri_rt2" {
  vpc_id = aws_vpc.vpc-950705.id
    route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_2.id
  }
}

resource "aws_route_table_association" "pub_rt_asso" {
  subnet_id = aws_subnet.pub_sub_1.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "pub_rt_asso2" {
  subnet_id = aws_subnet.pub_sub_2.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "pri_rt1_asso" {
  subnet_id = aws_subnet.pri_sub_1.id
  route_table_id = aws_route_table.pri_rt1.id
}

resource "aws_route_table_association" "pri_rt2_asso" {
  subnet_id = aws_subnet.pri_sub_2.id
  route_table_id = aws_route_table.pri_rt2.id
}


resource "aws_eip" "nat_eip1" {
  domain = "vpc"
}

resource "aws_eip" "nat_eip2" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw_1" {
  allocation_id = aws_eip.nat_eip2.id
  subnet_id = aws_subnet.pub_sub_1.id

  depends_on = [ aws_internet_gateway.my_igw ]
}

resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = aws_eip.nat_eip1.id
  subnet_id = aws_subnet.pub_sub_2.id

  depends_on = [ aws_internet_gateway.my_igw ]
}

