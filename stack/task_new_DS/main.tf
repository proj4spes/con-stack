/**
 * The task module creates an ECS task definition.
 *
 * Usage:
 *
 *     module "nginx" {
 *       source = "github.com/segmentio/stack/task"
 *       name   = "nginx"
 *       image  = "nginx"
 *     }
 *
 */

/**
 * Required Variables.
 */

variable "image" {
  description = "The docker image name, e.g nginx"
}

variable "name" {
  description = "The worker name, if empty the service name is defaulted to the image name"
}

/**
 * Optional Variables.
 */

variable "cpu" {
  description = "The number of cpu units to reserve for the container"
  default     = 512
}

variable "env_vars" {
  description = "The raw json of the task env vars"
  default     = "[]"
} # [{ "name": name, "value": value }]

variable "command" {
  description = "The raw json of the task command"
  default     = "[]"
} # ["--key=foo","--port=bar"]

variable "entry_point" {
  description = "The docker container entry point"
  default     = "[]"
}

variable "ports" {
  description = "The docker container ports"
  default     = "[]"
}

variable "image_version" {
  description = "The docker image version"
  default     = "latest"
}

variable "memory" {
  description = "The number of MiB of memory to reserve for the container"
  default     = 512
}

variable "log_driver" {
  description = "The log driver to use use for the container"
  default     = "journald"
}

variable "role" {
  description = "The IAM Role to assign to the Container"
  default     = ""
}

/**
 * Resources.
 */

# The ECS task definition.

resource "aws_ecs_task_definition" "main" {
  family        = "${var.name}"
  task_role_arn = "${var.role}"

  lifecycle {
    ignore_changes        = ["image"]
    create_before_destroy = true
  }
  memory =  256
  cpu    =  128 
  network_mode = "host" 

  container_definitions = <<EOF
[
        {
            "dnsSearchDomains": null,
            "logConfiguration": null,
            "entryPoint": null,
            "portMappings": [],
            "command": [
                "agent",
                "--config-dir=/consul/config",
                "--data-dir=/consul/data"
            ],
            "linuxParameters": null,
            "cpu": 20,
            "environment": [],
            "ulimits": null,
            "dnsServers": null,
            "mountPoints": [
                {
                    "readOnly": null,
                    "containerPath": "/consul/config",
                    "sourceVolume": "config"
                },
                {
                    "readOnly": null,
                    "containerPath": "/consul/data",
                    "sourceVolume": "data"
                }
            ],
            "workingDirectory": null,
            "dockerSecurityOptions": null,
            "memory": 128,
            "memoryReservation": null,
            "volumesFrom": [],
            "image": "consul:latest",
            "disableNetworking": null,
            "essential": true,
            "links": null,
            "hostname": null,
            "extraHosts": null,
            "user": null,
            "readonlyRootFilesystem": null,
            "dockerLabels": null,
            "privileged": null,
            "name": "consul"
        } ,

  {
            "dnsSearchDomains": null,
            "logConfiguration": null,
            "entryPoint": null,
            "portMappings": [],
            "command":  [
                "-retry-attempts=10",
                "-retry-interval=6000",
                "consul://localhost:8500"
            ],
            "linuxParameters": null,
            "cpu": 10,
            "environment": [],
            "ulimits": null,
            "dnsServers": null,
            "mountPoints": [
                {
                    "readOnly": true,
                    "containerPath": "/rootfs",
                    "sourceVolume": "root"
                },
                {
                    "readOnly": false,
                    "containerPath": "/var/run",
                    "sourceVolume": "var_run"
                },
                {
                    "readOnly": true,
                    "containerPath": "/sys",
                    "sourceVolume": "sys"
                },
                {
                    "readOnly": true,
                    "containerPath": "/var/lib/docker",
                    "sourceVolume": "var_lib_docker"
                },
                {
                    "readOnly": true,
                    "containerPath": "/tmp/docker.sock",
                    "sourceVolume": "docker_socket"
                }
            ],
            "workingDirectory": null,
            "dockerSecurityOptions": null,
            "memory": 80,
            "memoryReservation": null,
            "volumesFrom": [],
            "image": "gliderlabs/registrator:v7",
            "disableNetworking": null,
            "essential": true,
            "links": null,
            "hostname": null,
            "extraHosts": null,
            "user": null,
            "readonlyRootFilesystem": null,
            "dockerLabels": null,
            "privileged": null,
            "name": "registrator"
        }
]
EOF

  volume {
    name      = "config"
    host_path = "/opt/consul/config"
  }
  volume {
    name      = "data"
    host_path = "/opt/consul/data"
  }

  volume {
    name      = "root"
    host_path = "/"
  }

  volume {
    name      = "var_run"
    host_path = "/var/run"
  }

  volume {
    name      = "sys"
    host_path = "/sys"
  }

  volume {
    name      = "var_lib_docker"
    host_path = "/var/lib/docker/"
  }

  volume {
    name      = "docker_socket"
    host_path = "/var/run/docker.sock"
  }
}

/**
 * Outputs.
 */

// The created task definition name
output "name" {
  value = "${aws_ecs_task_definition.main.family}"
}

// The created task definition ARN
output "arn" {
  value = "${aws_ecs_task_definition.main.arn}"
}

// The revision number of the task definition
output "revision" {
  value = "${aws_ecs_task_definition.main.revision}"
}
