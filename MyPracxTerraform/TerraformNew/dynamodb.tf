resource "aws_dynamodb_table" "app-table" {
  name = "AppDynamoDBTable"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "AppDynamoDBTables"
  }
}