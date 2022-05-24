data "aws_ami" "app-ec2-ami" {

  owners      = ["amazon", "aws-marketplace"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "web-ec2" {
  ami                    = data.aws_ami.app-ec2-ami.id
  instance_type          = var.instance_type
  count                  = length(aws_subnet.app-vpc-public-subnet)
  subnet_id              = element(aws_subnet.app-vpc-public-subnet.*.id, count.index)
  vpc_security_group_ids = [aws_security_group.web-vpc-ec2-sg.id, ]
  iam_instance_profile   = aws_iam_instance_profile.ssm-role.name
  key_name               = "appkey"
  user_data              = file("userdata.sh")

  root_block_device {
    delete_on_termination = true
    iops                  = 200
    volume_size           = var.storage
    volume_type           = "gp3"
  }
  tags = {
    "Name"        = "web-ec2-${count.index + 1}"
    "Environment" = "Non Prod"
  }

}


output "web-ec2-instance" {
  value = zipmap(aws_instance.web-ec2.*.tags.Name, aws_instance.web-ec2.*.private_ip)
}