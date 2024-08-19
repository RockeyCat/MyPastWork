#!/bin/bash
sudo su -
yum update -y
yum install -y httpd.x86_64
systemctl start httpd.service
systemctl enable httpd.service
echo "Hello World from $(hostname -f)" > /var/www/html/index.html


yum update -y
yum install -y amazon-cloudwatch-agent

cat <<EOL > /opt/aws/amazon-cloudwatch-agent/bin/config.json
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
    },
    "metrics": {
        "namespace": "MyEC2Namespace",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "disk_usage_used",
                    "disk_io"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOL

# Start CloudWatch Agent with the configuration file
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a stop
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

# Ensure CloudWatch Agent starts on boot
systemctl enable amazon-cloudwatch-agent
