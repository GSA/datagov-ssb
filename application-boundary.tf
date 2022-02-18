data "cloudfoundry_space" "broker_space" {
  name     = var.broker_space.space
  org_name = var.broker_space.org
}

module "broker_eks" {
  source = "./broker"

  name                  = "ssb-eks"
  path                  = "./app-eks"
  broker_space          = var.broker_space
  client_spaces         = var.client_spaces
  enable_ssh            = var.enable_ssh
  memory                = 1024
  instances             = 2
  aws_access_key_id     = module.ssb-eks-broker-user.iam_access_key_id
  aws_secret_access_key = module.ssb-eks-broker-user.iam_access_key_secret
  aws_zone              = var.broker_zone
}

module "broker_smtp" {
  source = "./broker"

  name                  = "ssb-smtp"
  path                  = "./app-smtp"
  broker_space          = var.broker_space
  client_spaces         = var.client_spaces
  enable_ssh            = var.enable_ssh
  aws_access_key_id     = module.ssb-smtp-broker-user.iam_access_key_id
  aws_secret_access_key = module.ssb-smtp-broker-user.iam_access_key_secret
  aws_zone              = var.broker_zone
}

# This is the back-end k8s instance to be used by the ssb-solr app
resource "cloudfoundry_service_instance" "k8s_cluster" {
  name         = "ssb-solr-k8s"
  space        = data.cloudfoundry_space.broker_space.id
  service_plan = module.broker_eks.plans["aws-eks-service/raw"]
  tags         = ["k8s"]
  timeouts {
    create = "60m"
    update = "90m" # in case of an EKS destroy/create
    delete = "40m"
  }
  depends_on = [
    module.broker_eks,
    cloudfoundry_service_instance.solrcloud_broker_k8s_cluster
  ]
}

# resource "cloudfoundry_service_instance" "solrcloud_broker_k8s_cluster" {
#   name         = "ssb-solrcloud-k8s"
#   space        = data.cloudfoundry_space.broker_space.id
#   service_plan = module.broker_eks.plans["aws-eks-service/raw"]
#   tags         = ["k8s"]
#   json_params  = "{\"mng_min_capacity\": 8, \"mng_max_capacity\": 12, \"mng_desired_capacity\": 10}"
#   timeouts {
#     create = "60m"
#     update = "90m" # in case of an EKS destroy/create
#     delete = "40m"
#   }
#   depends_on = [
#     module.broker_eks
#   ]
# }

module "brokerpak-eks-terraform-provision" {
  source = "github.com/GSA/datagov-brokerpak-eks//terraform/provision?ref=main"

  subdomain            = var.eks_terraform_subdomain
  region               = var.eks_terraform_region
  zone                 = var.eks_terraform_zone
  instance_name        = var.eks_terraform_instance_name
  mng_min_capacity     = var.eks_terraform_mng_min_capacity
  mng_max_capacity     = var.eks_terraform_mng_max_capacity
  mng_desired_capacity = var.eks_terraform_mng_desired_capacity
}

module "broker_solrcloud" {
  source = "./broker"

  name          = "ssb-solrcloud"
  path          = "./app-solrcloud"
  broker_space  = var.broker_space
  client_spaces = var.client_spaces
  enable_ssh    = var.enable_ssh
  services      = [cloudfoundry_service_instance.solrcloud_broker_k8s_cluster.id]
}

module "broker_solr" {
  source = "./broker"

  name          = "ssb-solr"
  path          = "./app-solr"
  broker_space  = var.broker_space
  client_spaces = var.client_spaces
  enable_ssh    = var.enable_ssh
  services      = [cloudfoundry_service_instance.k8s_cluster.id]
}
