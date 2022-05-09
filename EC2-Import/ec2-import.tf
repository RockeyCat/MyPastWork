resource "aws_instance" "Test" {
  
  ami = "ami-04893cdb768d0f9ee"
  instance_type = "t2.micro"
  key_name = "mykey"
  security_groups = [ "sg-04716d755d4aff4d0" ]
  subnet_id = "subnet-0cb5c74b3fbbcaa90"

  tags = {
    "Name" = "Test"
  }
}