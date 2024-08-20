resource "aws_directory_service_directory" "adfs" {
  name = "corp.himanshujoshi.terraform.com"
  password = "Oneplus2@"
  edition = "Standard"
  type = "MicrosoftAD"


  vpc_settings {
    vpc_id = aws_vpc.app-vpc.id
    subnet_ids = aws_subnet.app-vpc-public-subnet[*].id

  }

  tags = {
    Project = "Foo"
  }


}


resource "aws_directory_service_conditional_forwarder" "adfs-fwd" {
  directory_id = aws_directory_service_directory.adfs.id
  remote_domain_name = "himanshujoshi.com"

  dns_ips = [
    "8.8.8.8",
    "8.8.4.4"
  ]
}