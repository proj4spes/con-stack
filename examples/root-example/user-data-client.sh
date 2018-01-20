#!/bin/bash
# This script is meant to be run in the User Data of each EC2 Instance while it's booting. The script uses the
# run-consul script to configure and start Consul in client mode. Note that this script assumes it's running in an AMI
# built from the Packer template in examples/consul-ami/consul.json.

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# These variables are passed in via Terraform template interplation
/opt/consul/bin/run-consul --ecs-mode --client --cluster-tag-key "${cluster_tag_key}" --cluster-tag-value "${cluster_tag_value}"

# You could add commands to boot your other apps here

echo 'SERVER_ENVIRONMENT=${environment}' >> /etc/environment
echo 'SERVER_GROUP=${name}' >> /etc/environment
echo 'SERVER_REGION=${region}' >> /etc/environment

mkdir -p /etc/ecs
echo 'ECS_CLUSTER=${name}' >> /etc/ecs/ecs.config
echo 'ECS_ENGINE_AUTH_TYPE=${docker_auth_type}' >> /etc/ecs/ecs.config

echo 'ECS_ENGINE_AUTH_DATA=${docker_auth_data}' >> /etc/ecs/ecs.config
