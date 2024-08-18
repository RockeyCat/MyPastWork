


resource "aws_db_instance" "app-db" {
  allocated_storage      = var.storage
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t2.micro"
  multi_az               = true
  username               = jsondecode(aws_secretsmanager_secret_version.sm-v.secret_string)["username"]
  password               = jsondecode(aws_secretsmanager_secret_version.sm-v.secret_string)["password"]
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.app-vpc-ec2-sg.id, ]
  iam_database_authentication_enabled = true
  monitoring_role_arn = aws_iam_role.rds-monitoring-role.arn
}


resource "aws_db_subnet_group" "app-db-sbg-g" {
  name       = "app-db-sb-g"
  subnet_ids = aws_subnet.app-vpc-private-subnet.*.id


  tags = {
    "Name" = "App-db-sg-g"
  }
}