data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "cluster" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = var.name
  }
}

resource "aws_subnet" "cluster" {
  count = 2

  availability_zone = data.aws_availability_zones.available.names[count.index]

  cidr_block              = "10.0.${count.index * 128}.0/17"
  vpc_id                  = aws_vpc.cluster.id
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-subnet-${format("%02d", count.index + 1)}"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_internet_gateway" "cluster" {
  vpc_id = aws_vpc.cluster.id

  tags = {
    Name = "${var.name}-gateway"
  }
}

resource "aws_route_table" "gateway" {
  vpc_id = aws_vpc.cluster.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cluster.id
  }
}

resource "aws_route_table_association" "cluster" {
  count = 2

  subnet_id      = aws_subnet.cluster[count.index].id
  route_table_id = aws_route_table.gateway.id
}
