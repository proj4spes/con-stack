# THESE TEMPLATES REQUIRE TERRAFORM VERSION 0.8 AND ABOVE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.9.3"
}
#----------------------------------------------------------------------------------------------------------------

/**
 * ECS Cluster creates a cluster with the following features:
 *
 *  - Autoscaling groups
 *  - Instance tags for filtering
 *  - EBS volume for docker resources
 *  - cluster tag ( for consul usage)
 *  - user data in launch conf ( for consul usage)
 * Usage:
 *
 *      module "cdn" {
 *        source               = "github.com//stack/ecs-cluster"
 *        environment          = "prod"
 *        name                 = "cdn"
 *        vpc_id               = "vpc-id"
 *        image_id             = "ami-id"
 *        subnet_ids           = ["1" ,"2"]
 *        key_name             = "ssh-key"
 *        security_groups      = "1,2"
 *        iam_instance_profile = "id"
 *        region               = "us-west-2"
 *        availability_zones   = ["a", "b"]
 *        instance_type        = "t2.small"
 *      }
 *
 */
#variable workaround to "compute count for dynamic list"
variable "nbr_sec_groups" {
  description = "Variable workaround to compute count for dynamic lists"
  default = 0
}

variable "name" {
  description = "The cluster name, e.g cdn"
}

variable "cluster_name" {
  description = "The cluster name, e.g cdn"
}


variable "environment" {
  description = "Environment tag, e.g prod"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "image_id" {
  description = "AMI Image ID"
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = "list"
}

variable "key_name" {
  description = "SSH key name to use"
}

variable "security_groups" {
  description = "Comma separated list of security groups"
}

variable "iam_instance_profile" {
  description = "Instance profile ARN to use in the launch configuration"
}

variable "cluster_tag_key_aj" {
  description = "tag key for consul cluster auto-join"
}
variable "cluster_tag_key" {
  description = "tag key for consul client  tagging  "
}
variable "cluster_tag_value" {
  description = "tag key value for consul cluster auto-join"
}

variable "region" {
  description = "AWS Region"
}

variable "availability_zones" {
  description = "List of AZs"
  type        = "list"
}

variable "instance_type" {
  description = "The instance type to use, e.g t2.small"
}

variable "instance_ebs_optimized" {
  description = "When set to true the instance will be launched with EBS optimized turned on"
  default     = true
}

variable "min_size" {
  description = "Minimum instance count"
  default     = 3
}

variable "max_size" {
  description = "Maxmimum instance count"
  default     = 100
}

variable "desired_capacity" {
  description = "Desired instance count"
  default     = 3
}

variable "associate_public_ip_address" {
  description = "Should created instances be publicly accessible (if the SG allows)"
  default = false
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  default     = 25
}

variable "docker_volume_size" {
  description = "Attached EBS volume size in GB"
  default     = 25
}

variable "docker_auth_type" {
  description = "The docker auth type, see https://godoc.org/github.com/aws/amazon-ecs-agent/agent/engine/dockerauth for the possible values"
  default     = ""
}

variable "docker_auth_data" {
  description = "A JSON object providing the docker auth data, see https://godoc.org/github.com/aws/amazon-ecs-agent/agent/engine/dockerauth for the supported formats"
  default     = ""
}

variable "extra_cloud_config_type" {
  description = "Extra cloud config type"
  default     = "text/cloud-config"
}

variable "extra_cloud_config_content" {
  description = "Extra cloud config content"
  default     = ""
}

variable "root_volume_delete_on_termination" {
  description = "Whether the volume should be destroyed on instance termination."
  default     = true
}

variable "health_check_grace_period" {
  description ="Time, in seconds, after instance comes into service before checking health."
  default     = 300
}

variable "wait_for_capacity_timeout" {
  description = "A maximum duration that Terraform should wait for ASG instances to be healthy before timing out. Setting this to '0' causes Terraform to skip all Capacity Waiting behavior."
  default     = "10m"
}

variable "health_check_type" {
  description = "Controls how health checking is done. Must be one of EC2 or ELB."
  default     = "ELB"
}

variable "server_rpc_port" {
  description = "The port used by servers to handle incoming requests from other agents."
}

variable "cli_rpc_port" {
  description = "The port used by all agents to handle RPC from the CLI."
}

variable "serf_lan_port" {
  description = "The port used to handle gossip in the LAN. Required by all agents."
}

variable "serf_wan_port" {
  description = "The port used by servers to gossip over the WAN to other servers."
}

variable "http_api_port" {
  description = "The port used by clients to talk to the HTTP API"
}

variable "dns_port" {
  description = "The port used to resolve DNS queries."
}

variable "ssh_port" {
  description = "The port used for SSH connections"
}

###################################################################################################################
#
#  resources
########################################################################################################

resource "aws_security_group" "cluster" {
  name        = "${var.name}-ecs-cluster"
  vpc_id      = "${var.vpc_id}"
  description = "Allows traffic from and to the EC2 instances of the cluster"

#  ingress {
#    from_port       = 0
#    to_port         = 0
#    protocol        = -1
#    security_groups = ["${split(",", var.security_groups)}"]
#  }

  tags {
    Name        = "ECS cluster (${var.name})"
    Environment = "${var.environment}"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group_rule" "allow_from_stack" {
  count       = "${var.nbr_sec_groups}"
  type        = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = -1
  source_security_group_id = "${element(split(",",var.security_groups),count.index)}"

  security_group_id = "${aws_security_group.cluster.id}"
}


 
resource "aws_security_group_rule" "allow_all_outbound" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.cluster.id}"
}

# ---------------------------------------------------------------------------------------------------------------------
# THE CONSUL-SPECIFIC INBOUND/OUTBOUND RULES COME FROM THE CONSUL-SECURITY-GROUP-RULES MODULE
# ---------------------------------------------------------------------------------------------------------------------

module "security_group_rules" {
  source = "../../modules/consul-security-group-rules"

  security_group_id                  = "${aws_security_group.cluster.id}"
  allowed_inbound_cidr_blocks        = ["0.0.0.0/0"]
  #allowed_inbound_security_group_ids = ["${var.security_groups}"]
  allowed_inbound_security_group_ids = []

  server_rpc_port = "${var.server_rpc_port}"
  cli_rpc_port    = "${var.cli_rpc_port}"
  serf_lan_port   = "${var.serf_lan_port}"
  serf_wan_port   = "${var.serf_wan_port}"
  http_api_port   = "${var.http_api_port}"
  dns_port        = "${var.dns_port}"
}

#----------------------------------------------------------------------------

resource "aws_ecs_cluster" "main" {
  name = "${var.name}"

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "ecs_cloud_config" {
   template = "${file("${path.module}/../../examples/root-example/user-data-client.sh")}"
#  template = "${file("${path.module}/files/cloud-config.yml.tpl")}"

  vars {
    environment      = "${var.environment}"
    name             = "${var.name}"
    region           = "${var.region}"
    docker_auth_type = "${var.docker_auth_type}"
    docker_auth_data = "${var.docker_auth_data}"
    #cluster_tag_key   = "${var.cluster_tag_key}"
    cluster_tag_key   = "${var.cluster_tag_key_aj}"
    cluster_tag_value = "${var.cluster_tag_value}"

  }
}

data "template_cloudinit_config" "cloud_config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.ecs_cloud_config.rendered}"
  }


  part {
    content_type = "${var.extra_cloud_config_type}"
    content      = "${var.extra_cloud_config_content}"
  }

}

resource "aws_launch_configuration" "main" {
  name_prefix = "${format("%s-", var.name)}"

  image_id                    = "${var.image_id}"
  instance_type               = "${var.instance_type}"
  ebs_optimized               = "${var.instance_ebs_optimized}"
  iam_instance_profile        = "${var.iam_instance_profile}"
  key_name                    = "${var.key_name}"
  security_groups             = ["${aws_security_group.cluster.id}"]
  user_data                   = "${data.template_cloudinit_config.cloud_config.rendered}"
  associate_public_ip_address = "${var.associate_public_ip_address}"

  # root
  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.root_volume_size}"
    delete_on_termination = "${var.root_volume_delete_on_termination}" 
  }

  # docker
  ebs_block_device {
    device_name = "/dev/xvdcz"
    volume_type = "gp2"
    volume_size = "${var.docker_volume_size}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main" {
  name = "${var.name}"

  #availability_zones   = ["${var.availability_zones}"]
  vpc_zone_identifier  = ["${var.subnet_ids}"]
  launch_configuration = "${aws_launch_configuration.main.id}"
  min_size             = "${var.min_size}"
  max_size             = "${var.max_size}"
  desired_capacity     = "${var.desired_capacity}"
  termination_policies = ["OldestLaunchConfiguration", "Default"]

  health_check_type         = "${var.health_check_type}"
  health_check_grace_period = "${var.health_check_grace_period}"
  wait_for_capacity_timeout = "${var.wait_for_capacity_timeout}"

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "${var.cluster_tag_key}"
    value               = "${var.cluster_tag_value}"
    propagate_at_launch = true
  }


  tag {
    key                 = "Name"
    value               = "${var.name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Cluster"
    value               = "${var.name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.environment}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.name}-scaleup"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.main.name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.name}-scaledown"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.main.name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name}-cpureservation-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "90"

  dimensions {
    ClusterName = "${aws_ecs_cluster.main.name}"
  }

  alarm_description = "Scale up if the cpu reservation is above 90% for 10 minutes"
  alarm_actions     = ["${aws_autoscaling_policy.scale_up.arn}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.name}-memoryreservation-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "90"

  dimensions {
    ClusterName = "${aws_ecs_cluster.main.name}"
  }

  alarm_description = "Scale up if the memory reservation is above 90% for 10 minutes"
  alarm_actions     = ["${aws_autoscaling_policy.scale_up.arn}"]

  lifecycle {
    create_before_destroy = true
  }

  # This is required to make cloudwatch alarms creation sequential, AWS doesn't
  # support modifying alarms concurrently.
  depends_on = ["aws_cloudwatch_metric_alarm.cpu_high"]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.name}-cpureservation-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "10"

  dimensions {
    ClusterName = "${aws_ecs_cluster.main.name}"
  }

  alarm_description = "Scale down if the cpu reservation is below 10% for 10 minutes"
  alarm_actions     = ["${aws_autoscaling_policy.scale_down.arn}"]

  lifecycle {
    create_before_destroy = true
  }

  # This is required to make cloudwatch alarms creation sequential, AWS doesn't
  # support modifying alarms concurrently.
  depends_on = ["aws_cloudwatch_metric_alarm.memory_high"]
}

resource "aws_cloudwatch_metric_alarm" "memory_low" {
  alarm_name          = "${var.name}-memoryreservation-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "10"

  dimensions {
    ClusterName = "${aws_ecs_cluster.main.name}"
  }

  alarm_description = "Scale down if the memory reservation is below 10% for 10 minutes"
  alarm_actions     = ["${aws_autoscaling_policy.scale_down.arn}"]

  lifecycle {
    create_before_destroy = true
  }

  # This is required to make cloudwatch alarms creation sequential, AWS doesn't
  # support modifying alarms concurrently.
  depends_on = ["aws_cloudwatch_metric_alarm.cpu_low"]
}

// The cluster name, e.g cdn
output "name" {
#  value = "${var.name}"
  value = "${aws_autoscaling_group.main.name}"
}

// The cluster security group ID.
output "security_group_id" {
  value = "${aws_security_group.cluster.id}"
}
