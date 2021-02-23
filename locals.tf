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

  broker_names = ["aws", "eks", "solr"]

  broker_set = [
    for key, name in local.broker_names : {
      key  = key
      name = name
    }
  ]

  space_set = [
    for key, space in local.spaces_in_orgs : {
      key   = key
      space = space
    }
  ]

  broker_registrations = [
    # in pair, element zero is a broker and element one is a space,
    for pair in setproduct(local.broker_set, local.space_set) : {
      name   = "ssb-${pair[1].space.org}-${pair[1].space.space}-${pair[0].name}"
      broker = pair[0].name
      space  = pair[1].key
    }
  ]
}
