resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = "${var.name}-vpc"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-igw"
  }
}

resource "aws_subnet" "public" {
  for_each                = zipmap(var.azs, var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-public-${each.key}"
  }
}

resource "aws_subnet" "private" {
  for_each          = zipmap(var.azs, var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key
  tags = {
    Name = "${var.name}-private-${each.key}"
  }
}

resource "aws_subnet" "database" {
  for_each          = zipmap(var.azs, var.database_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key
  tags = {
    Name = "${var.name}-db-${each.key}"
  }
}

resource "aws_subnet" "cache" {
  for_each          = zipmap(var.azs, var.cache_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key
  tags = {
    Name = "${var.name}-cache-${each.key}"
  }
}

resource "aws_subnet" "kafka" {
  for_each          = zipmap(var.azs, var.kafka_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key
  tags = {
    Name = "${var.name}-kafka-${each.key}"
  }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id
  tags = {
    Name = "${var.name}-nat"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-public"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-private"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db"
  subnet_ids = values(aws_subnet.database)[*].id
  tags = {
    Name = "${var.name}-db"
  }
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name}-cache"
  subnet_ids = values(aws_subnet.cache)[*].id
}

resource "aws_security_group" "database" {
  name        = "${var.name}-db"
  description = "Postgres access"
  vpc_id      = aws_vpc.this.id

  ingress {
    description      = "Postgres"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups  = [aws_security_group.eks_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "cache" {
  name        = "${var.name}-redis"
  description = "Redis access"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "Redis TLS"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "kafka" {
  name        = "${var.name}-kafka"
  description = "Kafka access"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = 9096
    to_port         = 9098
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vault" {
  name        = "${var.name}-vault"
  description = "Vault access"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = 8200
    to_port         = 8200
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  ingress {
    from_port       = 8201
    to_port         = 8201
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "eks_nodes" {
  name        = "${var.name}-eks-nodes"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Allow worker node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "eks_control_plane" {
  name        = "${var.name}-eks-control-plane"
  description = "Allow EKS control plane to reach worker nodes"
  vpc_id      = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "control_plane_to_nodes" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_control_plane.id
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "private_subnet_ids" {
  value = values(aws_subnet.private)[*].id
}

output "database_subnet_ids" {
  value = values(aws_subnet.database)[*].id
}

output "cache_subnet_ids" {
  value = values(aws_subnet.cache)[*].id
}

output "kafka_subnet_ids" {
  value = values(aws_subnet.kafka)[*].id
}

output "database_subnet_group_name" {
  value = aws_db_subnet_group.this.name
}

output "database_security_group_id" {
  value = aws_security_group.database.id
}

output "cache_security_group_id" {
  value = aws_security_group.cache.id
}

output "kafka_security_group_id" {
  value = aws_security_group.kafka.id
}

output "vault_security_group_id" {
  value = aws_security_group.vault.id
}

output "eks_node_security_group_id" {
  value = aws_security_group.eks_nodes.id
}

output "eks_control_plane_security_group_id" {
  value = aws_security_group.eks_control_plane.id
}
