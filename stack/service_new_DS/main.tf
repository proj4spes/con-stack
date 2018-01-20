/**
 * The service module creates an ecs service, task definition
 * elb and a route53 record under the local service zone (see the dns module).
 *
 * Usage:
 *
 *      module "auth_service" {
 *        source    = "github.com/segmentio/stack/service"
 *        name      = "auth-service"
 *        image     = "auth-service"
 *        cluster   = "default"
 *	  count     =  3
 *      }
 *
 */

/**
 * Required Variables.
 */



variable "environment" {
  description = "Environment tag, e.g prod"
}

variable "image" {
  description = "The docker image name, e.g nginx"
}

variable "name" {
  description = "The service name, if empty the service name is defaulted to the image name"
  default     = ""
}

variable "log_bucket" {
  description = "The log bucket name for elb classic solution - stack shared"
  default     = "log-bucket-elb-classic"
}

variable "instances_count" {
  description = "The number of instaces in ASG /ECS cluster "
  default     = 2
}

variable "version" {
  description = "The docker image version"
  default     = "latest"
}


variable "security_groups" {
  description = "Comma separated list of security group IDs that will be passed to the ELB module"
  default     = ""
}



variable "cluster" {
  description = "The cluster name or ARN"
}



/**
 * Options.
 */


variable "container_port" {
  description = "The container port"
  default     = 3000
}

variable "command" {
  description = "The raw json of the task command"
  default     = "[]"
}

variable "env_vars" {
  description = "The raw json of the task env vars"
  default     = "[]"
}

variable "desired_count" {
  description = "The desired count"
  default     = 2
}

variable "memory" {
  description = "The number of MiB of memory to reserve for the container"
  default     = 512
}

variable "cpu" {
  description = "The number of cpu units to reserve for the container"
  default     = 512
}

variable "protocol" {
  description = "The ELB protocol, HTTP or TCP"
  default     = "HTTP"
}

variable "iam_role" {
  description = "IAM Role ARN to use"
  default = ""
}


variable "deployment_minimum_healthy_percent" {
  description = "lower limit (% of desired_count) of # of running tasks during a deployment"
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "upper limit (% of desired_count) of # of running tasks during a deployment"
  default     = 200
}

/**
 * Resources.
 */
#
#data "aws_ecs_cluster" "daemonset" {
#  cluster_name = "${var.cluster}"
#}
#

resource "aws_ecs_service" "main" {
  name                               = "${module.task_new_DS.name}"
  cluster                            = "${var.cluster}"
  task_definition                    = "${module.task_new_DS.arn}"
  #desired_count                      = "${data.aws_ecs_cluster.daemonset.registered_container_instances_count}"
  desired_count                      = "${var.instances_count}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  placement_constraints {
    type       = "distinctInstance"
  }

  lifecycle {
    create_before_destroy = true
  }

}



resource "random_string" "tsk_name" {
  length = 3
  upper   = false
  number  = false
  special = false
  lower=true
}



module "task_new_DS" {
  source = "../task_new_DS"

  #name          = "${var.cluster}-${replace(var.image, "/", "-")}-${var.name}"
  name          = "${var.cluster}-${random_string.tsk_name.result}-${var.name}"
  image         = "${var.image}"
  image_version = "${var.version}"
  command       = "${var.command}"
  env_vars      = "${var.env_vars}"
  memory        = "${var.memory}"
  cpu           = "${var.cpu}"
  #role          = "${var.iam_role}"  role to task  , Fargate needs ??

      #  in PortMapping  do not use "hostPort": ${var.port}
  ports = <<EOF
  [
    {
      "containerPort": ${var.container_port}
    }
  ]
EOF
}



/**
 * Outputs.
 */


output "srv_id" {
  value = "${aws_ecs_service.main.id}"
}


output "tsk_arn" {
  value = "${module.task_new_DS.arn}"
}
