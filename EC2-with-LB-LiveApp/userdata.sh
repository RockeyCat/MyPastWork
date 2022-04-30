#!/bin/bash
sudo su -
yum update -y
yum install httpd -y
systemctl start httpd
systemctl enable httpd
echo "Hey My name is Himanshu- My First IaaC application" >> /var/www/html/index.html
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd