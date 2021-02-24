# datagov-ssb

The Supplementary Service Broker (SSB) fills gaps in cloud.gov's brokered
services.

Services are defined in a
[brokerpaks](https://github.com/pivotal/cloud-service-broker/blob/master/docs/brokerpak-intro.md),
bundles of Terraform and YAML that specifies the service should be advertised,
provisioned, bound, unbound, and unprovisioned.

## Prerequisites

1. Credentials for an S3 bucket that will store the state of the broker
   deployment

    This will ensure multiple people who manage the state of the broker will not
    conflict with each other. See the [Terraform
    documentation](https://www.terraform.io/docs/state/remote.html) for more
    information.

    For example, you can [create an S3 service instance on
    cloud.gov](https://cloud.gov/docs/services/s3/#how-to-create-an-instance)
    using the `basic` plan, then [extract the
    credentials](https://cloud.gov/docs/services/s3/#interacting-with-your-s3-bucket-from-outside-cloudgov)
    for use.

1. cloud.gov credentials with permission to register the service broker in the
   spaces where it should be available.

    For example, you can create a `space-deployer` [cloud.gov Service
    Account](https://cloud.gov/docs/services/cloud-gov-service-account/) in one
    of the spaces. 
    
    Then you can grant the `SpaceDeveloper` role to the service account for additional
    spaces as needed: 
    
    ```
    cf set-space-role <accountname> <orgname> <spacename> SpaceDeveloper
    ```

1. Credentials to be used for managing resources in AWS

    See the instructions [for the necessary IAM
    policies](https://github.com/pivotal/cloud-service-broker/blob/master/docs/aws-installation.md#aws-service-credentials).

## Dependencies

The broker deployment is specified and managed using
[Docker](https://www.docker.com/products/docker-desktop).

## Creating and installing the broker
<!-- (TODO
Try to do this automatically with terraform... It seems possible with
github_release and github_actions_secret in the github_provider!) -->
1. Download the broker binary, desired brokerpaks, and prerequisite binaries
   into the `/app` directory. 
    ```
    ./app-setup.sh
    ```

1. Copy the `backend.tfvars-template` and edit in the non-sensitive values for the S3 bucket.
    ```
    cp backend.tfvars-template backend.tfvars
    ${EDITOR} backend.tfvars
    ```

1. Copy the `.env.secrets-template` and edit in the sensitive values for the S3 bucket.
    ```
    cp .env.secrets-template .env.secrets
    ${EDITOR} .env.secrets
    ```

1. Copy the `terraform.tfvars-template` and edit in the values for the Cloud
   Foundry service account and your IaaS deployer accounts.
    ```
    cp terraform.tfvars-template terraform.tfvars
    ${EDITOR} terraform.tfvars
    ```

1. Run Terraform init to set up the backend.
    ```
    docker-compose run --rm terraform init -backend-config=backend.tfvars
    ```
1. Run Terraform apply and answer `yes` when prompted.
    ```
    docker-compose run --rm terraform apply
    ```

# Uninstalling and deleting the broker
Run Terraform destroy and answer `yes` when prompted.
```
docker-compose run --rm terraform destroy
```

# Continuously deploying the broker

This repository includes a GitHub Action that can continuously deploy the
`main` branch for you. To configure it, fork this repository in GitHub, then enter the
following into [the `Settings > Secrets` page](/settings/secrets) on your fork:

### Global secrets

| Secret Name | Description |
|-------------|-------------|
| AWS_ACCESS_KEY_ID | the S3 bucket key for Terraform state|
| AWS_SECRET_ACCESS_KEY | the S3 bucket secret for Terraform state |
| BUCKET | the S3 bucket name for Terraform state |


### Per-environment secrets

We are assuming you are using "staging" and "production" GitHub environments.

| Secret Name | Description |
|-------------|-------------|
| TF_VAR_AWS_ACCESS_KEY_ID | the key for brokering resources in AWS |
| TF_VAR_AWS_SECRET_ACCESS_KEY | the secret for brokering resources in AWS |
| TF_VAR_cf_username | the cloud-gov-service-account space-deployer username |
| TF_VAR_cf_password | the cloud-gov-service-account space-deployer password |

Once these secrets are in place, any changes to the main branch will be
deployed automatically.

---
## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for additional information.

## Public domain

This project is in the worldwide [public domain](LICENSE.md). As stated in
[CONTRIBUTING](CONTRIBUTING.md):

> This project is in the public domain within the United States, and copyright
> and related rights in the work worldwide are waived through the [CC0 1.0
> Universal public domain
> dedication](https://creativecommons.org/publicdomain/zero/1.0/).
>
> All contributions to this project will be released under the CC0 dedication.
> By submitting a pull request, you are agreeing to comply with this waiver of
> copyright interest.
