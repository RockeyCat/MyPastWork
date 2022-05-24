resource "aws_db_instance" "default" {
  allocated_storage      = var.storage
  db_subnet_group_name   = aws_db_subnet_group.app-db-sb-g.id
  engine                 = "mysql"
  engine_version         = "8.0.20"
  instance_class         = "db.t2.micro"
  multi_az               = true
  name                   = "mydb-default"
  username               = "admin"
  password               = file("password.txt")
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.db-ec2-vpc-sg.id, ]
}



resource "aws_db_subnet_group" "app-db-sb-g" {
  name       = "app-db-sb-g"
  subnet_ids = aws_subnet.app-vpc-private-subnet.*.id

  tags = {
    "Name" = "App-db-Sg-g"
  }
}