# datagov-ssb

The Supplementary Service Broker (SSB) fills gaps in cloud.gov's brokered
services.

Services are defined in a
[brokerpaks](https://github.com/pivotal/cloud-service-broker/blob/master/docs/brokerpak-intro.md),
bundles of Terraform and YAML that specifies the service should be
advertised, provisioned, bound, unbound, and unprovisioned.

# Dependencies

The broker deployment is specified and managed using
[Terraform](https://www.terraform.io/). You must have at least Terraform version
`0.12.6` installed.

# Creating and installing the broker

Download the broker binary and any desired brokerpak files into `/app`. (TODO
Try to do this automatically with terraform... It seems possible with
[github_release in the github_provider](https://registry.terraform.io/providers/hashicorp/github/latest/docs/data-sources/release)!)
```

(cd app && curl -L -O https://github.com/pivotal/cloud-service-broker/releases/download/sb-0.1.0-rc.34-aws-0.0.1-rc.108/cloud-service-broker)
(cd app && curl -L -O https://github.com/pivotal/cloud-service-broker/releases/download/sb-0.1.0-rc.34-aws-0.0.1-rc.108/aws-services-0.0.1-rc.108.brokerpak)

```

Copy the `terraform.tfvars-template` and edit in the values for any needed service accounts.
```
cp terraform.tfvars-template terraform.tfvars
${EDITOR} terraform.tfvars
```

Run Terraform apply and answer `yes` when prompted.
```
terraform apply
```

# Uninstalling and deleting the broker
Run Terraform destroy and answer `yes` when prompted.
```
terraform destroy
```

# Sharing the deployment in a team
Ensure everyone running terraform must read/write the same
`.tfstate` file. See the [Terraform
documentation](https://www.terraform.io/docs/state/remote.html) for more information.

---
## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for additional information.

## Public domain

This project is in the worldwide [public domain](LICENSE.md). As stated in [CONTRIBUTING](CONTRIBUTING.md):

> This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
>
> All contributions to this project will be released under the CC0 dedication. By submitting a pull request, you are agreeing to comply with this waiver of copyright interest.
