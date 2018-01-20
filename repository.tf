variable image_name {
          description = "The name of a private registry (ecr)"
}

variable max_n_t {
          description = " max number of tagged image"
}

variable max_age {
          description = "The max age of untagged image"
}


data "aws_iam_role" "ecr" {
  name = "ecr"
}

module "ecr" {
  source              = ".//terraform-aws-ecr"
  name                = "${var.image_name}"
  namespace           = "${var.name}"
  stage               = "${var.environment}"
  #roles               = ["${data.aws_iam_role.ecr.name}"]    count can not computed 
  roles               = []
   max_n_t             = 30
   max_age             = 60
}

