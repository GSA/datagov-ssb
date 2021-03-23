# Expand the map of target orgs+spaces into a form that's useful for indexing
# and iterating on.
# 
# This idea came from 
# https://www.reddit.com/r/Terraform/comments/d8em03/terraform_12_nested_for_each/f1ckkhs/

locals {
  org_spaces = flatten([
    for on, s in var.client_spaces : [
      for sn in s : {
        org   = on
        space = sn
      }
    ]
  ])

  spaces_in_orgs = {
    for os in local.org_spaces : "${os.org}/${os.space}" => {
      org   = os.org
      space = os.space
    }
  }

  # By URL-encoding the password, we can ensure that upon `cf ssh`,
  # `cloud-service-broker client` will be functional without having to adjust
  # environment variables.
  processed_password = urlencode(random_password.client_password.result)

}
