#!/bin/bash
set -e

instance_id=1$
aws_access_key_id=$2
aws_secret_access_key=$3
region="us-east-1"

echo ***************************************************"Configuring AWS CLI"
aws configure set aws_access_key_id "$aws_access_key_id"
aws configure set aws_secret_access_key "$aws_secret_access_key"
aws configure set region "$region"

function install_instance() {
    if command -v aws &> /dev/null; then
        echo "AWS CLI is already installed, updating..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install --update
    else
        echo "Installing AWS CLI..."
        sudo apt-get update
        sudo apt-get install -y unzip
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
    fi
}
install_instance

if [ -z $instances ];then
    echo "Aborting no instance ID found"
    exit 1
fi

echo **************"$(date): Attempting to shut down instance $instance_id in region $region"

aws ec2 stop-instances --instance-ids $instance_id --region $region


if [ $? -eq 0 ]; then
  echo "$(date): Successfully initiated shutdown for instance $instance_id"
else
  echo "$(date): Failed to initiate shutdown for instance $instance_id" >&2
fi

echo "$instance_id: Runner succesfully stop"