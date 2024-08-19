
data "archive_file" "lambda" {
  type = "zip"
  source_file = "lambda.js"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "lambda-function" {
  

  filename = "lambda_function_payload.zip"
  function_name = "lambda_function_name"
  role = aws_iam_role.aws-lambda-role.arn
  handler = "index.test"

  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime = "nodejs18.x"
  
  environment {
    variables = {
     DYNAMODB_TABLE_NAME = aws_dynamodb_table.app-table.name
    }
  }
    vpc_config {
      subnet_ids = aws_subnet.app-vpc-private-subnet.*.id
      security_group_ids = [aws_security_group.app-vpc-ec2-sg.id,]
}

timeout = 300
}