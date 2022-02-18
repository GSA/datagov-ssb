# See vars.tf for more information
client_spaces = {
  gsa-datagov = ["management-staging"]
}
broker_space = {
  org   = "gsa-datagov"
  space = "management-staging"
}
broker_zone = "ssb-staging.data.gov"
manage_zone = true

# Terraform parameters for eks
eks_terraform_subdomain            = "solrcloud-k8s"
eks_terraform_region               = "us-west-2"
eks_terraform_instance_name        = "solrcloud"
eks_terraform_mng_min_capacity     = 1
eks_terraform_mng_max_capacity     = 11
eks_terraform_mng_desired_capacity = 10
