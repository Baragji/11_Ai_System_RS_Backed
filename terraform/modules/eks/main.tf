resource "aws_iam_role" "cluster" {
  count = var.cluster_role_arn == "" ? 1 : 0
  name  = "${var.name}-eks-cluster"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume.json
}

data "aws_iam_policy_document" "cluster_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

locals {
  cluster_role_arn = var.cluster_role_arn != "" ? var.cluster_role_arn : aws_iam_role.cluster[0].arn
}

resource "aws_eks_cluster" "this" {
  name     = "${var.name}-eks"
  role_arn = local.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids      = [var.control_plane_security_group_id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  kubernetes_network_config {
    service_ipv4_cidr = var.service_ipv4_cidr
  }

  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }

  tags = {
    Name = "${var.name}-eks"
  }
}

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${aws_eks_cluster.this.name}/cluster"
  retention_in_days = 30
}

resource "aws_iam_role" "node" {
  count = var.node_role_arn == "" ? 1 : 0
  name  = "${var.name}-eks-nodes"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
}

data "aws_iam_policy_document" "node_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

locals {
  node_role_arn = var.node_role_arn != "" ? var.node_role_arn : aws_iam_role.node[0].arn
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  count      = var.node_role_arn == "" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node[0].name
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  count      = var.node_role_arn == "" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node[0].name
}

resource "aws_iam_role_policy_attachment" "node_registry" {
  count      = var.node_role_arn == "" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node[0].name
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name}-core"
  node_role_arn   = local.node_role_arn
  subnet_ids      = var.subnet_ids
  version         = var.cluster_version
  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }
  instance_types = var.node_instance_types
  capacity_type  = "ON_DEMAND"

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.nodes.id
    version = "$Latest"
  }

  remote_access {
    ec2_ssh_key               = var.ssh_key_name
    source_security_group_ids = [var.bastion_security_group_id]
  }

  labels = {
    "node.kubernetes.io/lifecycle" = "on-demand"
  }

  tags = {
    Name = "${var.name}-eks-core"
  }
}

resource "aws_launch_template" "nodes" {
  name_prefix   = "${var.name}-eks-nodes-"
  image_id      = var.node_ami_id
  instance_type = var.node_instance_types[0]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 100
      volume_type = "gp3"
      encrypted   = true
      kms_key_id  = var.kms_key_arn
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name}-eks-node"
    }
  }

  metadata_options {
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }
}

output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}
