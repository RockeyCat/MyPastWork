resource "aws_secretsmanager_secret" "sm-secret" {
  
name = "sm-secret"


tags = {
  "Name" = "SM-Secret-Credentials"
}
}



resource "aws_secretsmanager_secret_policy" "sm-policy" {
  
  secret_arn = aws_secretsmanager_secret.sm-secret.arn
  policy = data.aws_iam_policy_document.sm-policy.json
}

resource "aws_secretsmanager_secret_rotation" "sm-rotation" {
  secret_id = aws_secretsmanager_secret.sm-secret.id

    rotation_rules {
      automatically_after_days = 30
      
    }

}


resource "aws_secretsmanager_secret_version" "sm-v" {
  secret_id = aws_secretsmanager_secret.sm-secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password

  })
}


