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