resource "aws_eks_node_group" "aws-cluster-node-group" {
  cluster_name = aws_eks_cluster.aws-cluster.name
  node_role_arn = aws_iam_instance_profile.ssm-role.arn
  subnet_ids = aws_subnet.app-vpc-private-subnet.*.id
  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size 
    min_size     = var.min_size
  }

  update_config {
    max_unavailable = var.min_size
  }

  instance_types = [var.instance_type,]

  remote_access {
    ec2_ssh_key = "app_key.pem"
    source_security_group_ids = [aws_security_group.app-vpc-ec2-sg.id, ]
  }


  depends_on = [ aws_iam_role.ssm-role]

  tags = {
    Name = "${var.cluster_name}-${var.node_group_name}-worker"
    Environment = "${var.pracx}"  
    Project = "${var.cluster_name}" 
  }
}

output "node_group_name" {
  value = aws_eks_node_group.aws-cluster-node-group.node_group_name
}

output "node_group_role_arn" {
  value = aws_iam_role.ssm-role.arn
}
