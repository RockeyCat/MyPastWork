variable "region" {
  type    = string
  default = "ap-south-1"
}

##############SINGLE CIDR DEFINATION##################
variable "eks-vpc" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Mentioned CIDR for our VPC"

}

locals {
  cluster_name = "eks-cluster"
}

provider "aws" {
  region                   = var.region
  shared_config_files      = ["C:\\Users\\HP\\.aws\\config"]
  shared_credentials_files = ["C:\\Users\\HP\\.aws\\credentials"]
}

data "aws_availability_zones" "azs" {
  state = "available"
}

##########VPC DEFINATION##################

resource "aws_vpc" "eks-vpc" {
  cidr_block           = var.eks-vpc
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    "Name" = "EKS-VPC-Main"
  }
}

##########Public Subnet  DEFINATION##################

resource "aws_subnet" "public-subnet" {
  vpc_id                                      = aws_vpc.eks-vpc.id
  count                                       = var.eks-vpc == "10.0.0.0/16" ? 3 : 0
  cidr_block                                  = cidrsubnet(var.eks-vpc, 8, count.index)
  map_public_ip_on_launch                     = "true"
  enable_resource_name_dns_a_record_on_launch = "true"
  availability_zone                           = data.aws_availability_zones.azs.names[count.index]

  tags = {
    "Name" = "Public-Subnet-${count.index + 1}"

  }

}

/*
##########Private Subnet  DEFINATION##################

resource "aws_subnet" "private-subnet" {
  vpc_id                                      = aws_vpc.eks-vpc.id
  count                                       = var.eks-vpc == "10.0.0.0/16" ? 3 : 0
  cidr_block                                  = cidrsubnet(var.eks-vpc, 8, count.index + 3)
  map_public_ip_on_launch                     = "true"
  enable_resource_name_dns_a_record_on_launch = "true"
  availability_zone                           = data.aws_availability_zones.azs.names[count.index]

  tags = {
    "Name" = "Private-Subnet-${count.index + 1}"
  }

}



resource "aws_eip" "eip" {
  count = var.eks-vpc == "10.0.0.0/16" ? 3 : 0
  vpc   = true
}


resource "aws_nat_gateway" "eks-vpc-n-gw" {
  count         = var.eks-vpc == "10.0.0.0/16" ? 3 : 0
  allocation_id = element(aws_eip.eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public-subnet.*.id, count.index)

  tags = {
    "Name" = "eks-vpc-n-gw-${count.index + 1}"
  }
}


resource "aws_route" "eks-vpc-r-private" {
  count                  = var.eks-vpc == "10.0.0.0/16" ? 3 : 0
  route_table_id         = aws_route_table.eks-vpc-rt-private.id
  gateway_id             = element(aws_nat_gateway.eks-vpc-n-gw.*.id, count.index)
  destination_cidr_block = element(aws_subnet.private-subnet.*.cidr_block, count.index)
}


resource "aws_route_table" "eks-vpc-rt-private" {
  vpc_id = aws_vpc.eks-vpc.id

  tags = {
    "Name" = "eks-vpc-rt-private"
  }
}


resource "aws_route_table_association" "eks-vpc-rt-a-private" {
  count          = var.eks-vpc == 3 ? 3 : 0
  route_table_id = aws_route_table.eks-vpc-rt-private.id
  subnet_id      = element(aws_subnet.private-subnet.*.id, count.index)
}
*/

resource "aws_internet_gateway" "eks-vpc-ig" {
  vpc_id = aws_vpc.eks-vpc.id
  tags = {
    "Name" = "eks-vpc-ig"
  }
}


resource "aws_route" "eks-vpc-r" {
  route_table_id         = aws_route_table.eks-vpc-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks-vpc-ig.id
}


resource "aws_route_table" "eks-vpc-rt" {
  vpc_id = aws_vpc.eks-vpc.id

  tags = {
    "Name" = "eks-vpc-rt"
  }
}


resource "aws_route_table_association" "eks-vpc-rt-a" {
  count          = length(aws_subnet.public-subnet) == 3 ? 3 : 0
  subnet_id      = element(aws_subnet.public-subnet.*.id, count.index)
  route_table_id = aws_route_table.eks-vpc-rt.id

}


data "aws_ami" "managed_ami" {
  most_recent = true
  owners      = ["amazon", "aws-marketplace"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


locals {
  ingress_rules = [{
      name = "HTTPS"
      port = 443
      description = "Secured Port Only"
  },
  {
      name = "HTTP"
      port = 80
      description = "UnSecured Port Only"
  },
  {
      name = "SSH"
      port = 22
      description = "SSH Port Only"
  }
  ]
}


resource "aws_security_group" "eks-vpc-sg" {
  vpc_id = aws_vpc.eks-vpc.id
  name = "eks-vpc-sg"
  description = "Cluster-SG"
  

  dynamic ingress {
      for_each = local.ingress_rules
      content {
            description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]

    }

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "app-vp-ec2-sg"
  }
}


resource "aws_iam_role" "eks-role" {
  name = "eks-role"
  
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}




data "aws_iam_policy" "AmazonEKSServicePolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

data "aws_iam_policy" "AmazonEKSClusterPolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "AmazonEKSWorkerNodePolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

data "aws_iam_policy" "AmazonEKS_CNI_Policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

data "aws_iam_policy" "AmazonEC2ContainerRegistryReadOnly" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  role = aws_iam_role.eks-role.name
  policy_arn = data.aws_iam_policy.AmazonEKSClusterPolicy.arn

}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  role = aws_iam_role.eks-role.name
  policy_arn = data.aws_iam_policy.AmazonEKSServicePolicy.arn

}

resource "aws_eks_cluster" "eks-cluster" {
  name = "eks-cluster"
  role_arn = aws_iam_role.eks-role.arn
  vpc_config {
    
    subnet_ids = aws_subnet.public-subnet[*].id
    security_group_ids = [aws_security_group.eks-vpc-sg.id]
  }

  tags = {
    "Name" = "EKS-Cluster"
  }
}


resource "aws_iam_role" "eks-nodes-role" {
  name = "Eks-Cluster-nodes"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}



resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role = aws_iam_role.eks-nodes-role.name
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  role = aws_iam_role.eks-nodes-role.name
  policy_arn = data.aws_iam_policy.AmazonEKSWorkerNodePolicy.arn
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  role = aws_iam_role.eks-nodes-role.name
  policy_arn = data.aws_iam_policy.AmazonEC2ContainerRegistryReadOnly.arn
}
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  role = aws_iam_role.eks-nodes-role.name
  policy_arn = data.aws_iam_policy.AmazonEKS_CNI_Policy.arn
}


resource "aws_eks_node_group" "eks-node-group" {
  cluster_name = aws_eks_cluster.eks-cluster.name
  node_group_name = "eks-cluster-ng"
  node_role_arn = aws_iam_role.eks-nodes-role.arn
  subnet_ids = aws_subnet.public-subnet[*].id

  scaling_config {
    desired_size = 1
    max_size = 1
    min_size = 1
  }


  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
  ]
}


output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks-cluster.endpoint
}

output "eks_cluster_certificate_authority" {
  value = aws_eks_cluster.eks-cluster.certificate_authority
}
