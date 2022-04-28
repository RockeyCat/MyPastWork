variable "aws_access_key" {
  
}
variable "aws_secret_key" {
  
}
variable "region" {
  
}

variable "cluster_name" {
  type = string
  default = "my-cluster"
}

variable "subnet_id" {
  type = list
  default = ["",""]
}


provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.region
}

resource "aws_default_vpc" "default" {
  tags = {
    "Name" = "Default VPC"
  }
}



resource "aws_iam_role" "my-cluster-role" {
  name = "my-cluster-role"

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

resource "aws_iam_role_policy_attachment" "my-cluster-awseksp" {
  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.my-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "my-cluster-awseksvpcrcp" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role = aws_iam_role.my-cluster-role.name
}


resource "aws_eks_cluster" "my-cluster" {
vpc_config {
  subnet_ids = var.subnet_id
}
name = "my-cluster"
role_arn = aws_iam_role.my-cluster-role.arn
enabled_cluster_log_types = [ "api","audit" ]

depends_on = [
  aws_iam_role_policy_attachment.my-cluster-awseksp,
  aws_iam_role_policy_attachment.my-cluster-awseksvpcrcp,
  aws_cloudwatch_log_group.my-cluster
]
}

resource "aws_cloudwatch_log_group" "my-cluster" {
  name = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
}

data "tls_certificate" "my-cluster" {
  url = aws_eks_cluster.my-cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "my-cluster" {
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.my-cluster.certificates[0].sha1_fingerprint]
  url = aws_eks_cluster.my-cluster.identity[0].oidc[0].issuer
}

output "endpoint" {
  value = aws_eks_cluster.my-cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.my-cluster.certificate_authority[0].data
}