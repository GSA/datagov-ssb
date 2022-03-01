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
    module.broker_eks
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

resource "cloudfoundry_user_provided_service" "ssb-solrcloud-k8s" {
  name             = "aws-eks-service"
  space            = var.broker_space.space
  credentials_json = <<-JSON
    "credentials": {
      "certificate_authority_data": "${module.brokerpak-eks-terraform.certificate_authority_data}",
      "domain_name": "${module.brokerpak-eks-terraform.domain_name}",
      "kubeconfig": "${module.brokerpak-eks-terraform.kubeconfig}",
      "namespace": "${module.brokerpak-eks-terraform.namespace}",
      "server": "${module.brokerpak-eks-terraform.server}",
      "token": "${module.brokerpak-eks-terraform.token}"
    }
  JSON
}

module "broker_solrcloud" {
  source = "./broker"

  name          = "ssb-solrcloud"
  path          = "./app-solrcloud"
  broker_space  = var.broker_space
  client_spaces = var.client_spaces
  enable_ssh    = var.enable_ssh
  # services      = [cloudfoundry_service_instance.solrcloud_broker_k8s_cluster.id]
  services = [cloudfoundry_user_provided_service.ssb-solrcloud-k8s.id]
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
