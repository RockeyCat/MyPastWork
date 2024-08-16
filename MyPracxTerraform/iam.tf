resource "aws_iam_role" "ssm-role" {


  name = "ssm-role"
  assume_role_policy = jsonencode({

    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

}

data "aws_iam_policy" "default" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

}


resource "aws_iam_role_policy_attachment" "name" {
  role       = aws_iam_role.ssm-role.name
  policy_arn = data.aws_iam_policy.default.arn
}

resource "aws_iam_instance_profile" "ssm-role" {
  name = "ssm-role"
  role = aws_iam_role.ssm-role.name
}

# Attach Policies to the Node Group IAM Role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_attachment" {
  role       = aws_iam_role.ssm-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  role       = aws_iam_role.ssm-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ec2_policy_attachment" {
  role       = aws_iam_role.ssm-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "beanstalk_service" {
    role = aws_iam_role.ssm-role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

resource "aws_iam_role_policy_attachment" "beanstalk_service_health" {
    role = aws_iam_role.ssm-role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "beanstalk_ec2_worker" {
   
    role = aws_iam_role.ssm-role.name
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "beanstalk_ec2_web" {
    role = aws_iam_role.ssm-role.name
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "beanstalk_ec2_container" {
    role = aws_iam_role.ssm-role.name
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}



resource "aws_iam_role" "aws-cluster-role" {
  name = "eks-cluster-role"

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
  role       = aws_iam_role.aws-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "my-cluster-awseksvpcrcp" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.aws-cluster-role.name
}



data "aws_iam_policy_document" "codepipeline" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline-role" {
  name = "codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"
  
  actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
  ]
  resources = [aws_s3_bucket.aws-s3-bucket.arn, "${aws_s3_bucket.aws-s3-bucket.arn}/*"]
  }


  statement {
    effect = "Allow"
    actions = ["codestart-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.app-codestar.arn]
  }

  statement {

    effect = "Allow"

    actions = ["codebuild:BatchGetBuilds",
      "codebuild:StartBuild",]


      resources = ["*"]
  }

}


resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.codepipeline-role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}




data "aws_kms_alias" "s3kmskey" {
  name = "alias/aws/ebs"
}

output "default_kms_key_arn" {
  value = data.aws_kms_alias.s3kmskey.target_key_arn
}