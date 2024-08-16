resource "aws_cloudwatch_log_group" "my-cluster" {
  name = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.retention_in_days
}



resource "aws_eks_cluster" "aws-cluster" {
  name = var.cluster_name
  role_arn = aws_iam_role.aws-cluster-role.arn
  vpc_config {
    subnet_ids = aws_subnet.app-vpc-private-subnet.*.id
    endpoint_private_access = true
    endpoint_public_access = false
    security_group_ids = [aws_security_group.app-vpc-ec2-sg.id,]
  }
  

  depends_on = [ 
    aws_iam_role_policy_attachment.my-cluster-awseksvpcrcp,
    aws_iam_role_policy_attachment.my-cluster-awseksp,
    aws_cloudwatch_log_group.my-cluster]
}


data "tls_certificate" "eks-certs" {
  url = aws_eks_cluster.aws-cluster.identity[0].oidc[0].issuer
}
resource "aws_iam_openid_connect_provider" "eks-cluster" {
  client_id_list = ["s3.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks-certs.certificates[0].sha1_fingerprint]
  url = aws_eks_cluster.aws-cluster.identity[0].oidc[0].issuer
}

output "endpoint" {
  value = aws_eks_cluster.aws-cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.aws-cluster.certificate_authority[0].data
}