locals {
  raw_password     = file("password.txt")
  decoded_password = base64decode(local.raw_password)
}


resource "aws_db_instance" "app-db" {
  allocated_storage      = var.storage
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t2.micro"
  multi_az               = true
  username               = "master"
  password               = local.decoded_password
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.app-vpc-ec2-sg.id, ]



}


resource "aws_db_subnet_group" "app-db-sbg-g" {
  name       = "app-db-sb-g"
  subnet_ids = aws_subnet.app-vpc-private-subnet.*.id


  tags = {
    "Name" = "App-db-sg-g"
  }
}