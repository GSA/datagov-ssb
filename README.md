# usnotify-ssb

Part of [Notify.gov](https://notify.gov/)

The Supplementary Service Broker (SSB) manages the lifecycle of services, filling gaps in [cloud.gov](https://cloud.gov)'s brokered services. The SSB is compliant with the [Open Service Broker API](https://www.openservicebrokerapi.org/) specification. Using this API, the service broker advertises a catalog of service offerings and service plans, and interprets calls for provision (create), bind, unbind, and deprovision (delete). What the broker does with each call can vary between services. In general, `provision` reserves resources on a service and `bind` delivers information to an app necessary for accessing the resource. The reserved resource is called a service instance.

What a service instance represents can vary by service, for example a single database on a multi-tenant server, a dedicated cluster, or even just an account on a web app. Clients, often platforms in their own right, interact with the SSB to provision and manage instances of the services offered. The broker provides all the information that an application or container needs to connect to the service instance, regardless of how or where the service is running.

The SSB can also be used from the command-line with [`eden`](https://github.com/starkandwayne/eden), or integrated into other platforms that make use of the [OSBAPI](https://www.openservicebrokerapi.org).

The SSB currently provides [SMTP](https://github.com/GSA/datagov-brokerpak-smtp) and [SMS](https://github.com/GSA/ttsnotify-brokerpak-sns) services.

Services are defined in a
[brokerpaks](https://github.com/cloudfoundry/cloud-service-broker/blob/main/docs/brokerpak-intro.md),
bundles of Terraform and YAML that specify how each service should be advertised,
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
    for use. Running `SERVICE_INSTANCE_NAME=<servicename> ./s3creds.sh` will create the service-key and provide the necessary environment variables.

1. Cloud Foundry credentials with permission to register the service broker in
   the spaces where it should be available.

    For example, you can create a `space-deployer` [cloud.gov Service
    Account](https://cloud.gov/docs/services/cloud-gov-service-account/) in one
    of the spaces, then grant the `SpaceDeveloper` role to the service account for additional
    spaces as needed:

    ```bash
    cf create-service cloud-gov-service-account space-deployer ci-deployer
    cf create-service-key ci-deployer ssb-deployer-key
    cf service-key ci-deployer ssb-deployer-key
    cf set-space-role <accountname> <orgname> <additional-spacename> SpaceDeveloper
    ```

1. Credentials to be used for managing resources in AWS

    To configure domains, set quotas, and create service accounts with the correct permissions, deployment requires an AWS access key id and secret for a user with at least IAM and Route53 policies, and the ability to make support requests.

## Dependencies

The broker deployment is specified and managed using
[Docker](https://www.docker.com/products/docker-desktop).

## Creating and installing the broker

<!-- (TODO
Try to do this automatically with terraform... It seems possible with
github_release and github_actions_secret in the github_provider!) -->

1. Download the broker binary, desired brokerpaks, and prerequisite binaries
   into the respective `/app` directories by running these two shell scripts:

    ```bash
    ./app-setup-smtp.sh
    ./app-setup-sms.sh
    ```

1. Copy the `backend.tfvars-template` and edit in the non-sensitive values for the S3 bucket.

    ```bash
    cp backend.tfvars-template backend.tfvars
    ${EDITOR} backend.tfvars
    ```
    Paste in the GUID (into `bucket`) and the `region` of the S3 bucket that holds Terraform state. These should be the same as [used in the notifications-api](https://github.com/GSA/notifications-api/blob/7a1c49b7c70245f59f62d8b0ea4311f6393c4fe4/terraform/sandbox/providers.tf#L11) repo.

1. Copy the `.backend.secrets-template` and edit in the sensitive values for the S3 bucket.

    ```bash
    cp .backend.secrets-template .backend.secrets
    ${EDITOR} .backend.secrets
    ```
    The file must contain credentials for the S3 bucket that holds Terraform state. If you have previously set yourself up to run Terraform in Notify's other repos, then you may have these credentials in your local `~/.aws/credentials` file and you may copy them from there. Otherwise, [use these instructions](https://github.com/GSA/notifications-api/tree/main/terraform#use-bootstrap-credentials).

1. Set a variable with the name of the environment you want to work with

    ```bash
    export ENV_NAME=[environment_name]
    ```
    If you are new to the project, you will probably start with the environment name `development`.

1. You don't need to do this unless you are creating a brand-new environment. If you are doing that, copy the `terraform.tfvars-template` and edit in any variable customizations for the target environment.

    ```bash
    cp terraform.tfvars-template terraform.${ENV_NAME}.tfvars
    ${EDITOR} terraform.${ENV_NAME}.tfvars
    ```

1. Copy the `.env.secrets-template` and edit in the values for the Cloud
Foundry service account and your AWS deployment user.

    ```bash
    cp .env.secrets-template .env.${ENV_NAME}.secrets
    ${EDITOR} .env.${ENV_NAME}.secrets
    ```
    * `TF_VAR_aws_access_key_id` and `TF_VAR_aws_secret_access_key` are created within the AWS console, associated with an IAM role with appropriate permissions.
    * `TF_VAR_cf_username` and `password` refer to SpaceDeployer credentials which were output from the `cf service-key` command in the [prerequisites](#prerequisites).
    * `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are the same as what you saved in `.backend.secrets` in a previous step.

1. Run Terraform init to set up the backend.

    ```bash
    docker-compose --env-file .backend.secrets run --rm terraform init -backend-config backend.tfvars
    ```
    If you get the error `Failed to query available provider packages` that's a Zscaler problem.

1. Create a Terraform workspace for your environment and switch to it

    ```bash
    docker-compose --env-file=.backend.secrets run --rm terraform workspace new ${ENV_NAME}
    docker-compose --env-file=.backend.secrets run --rm terraform workspace select ${ENV_NAME}
    ```

1. Run Terraform plan and review the output

    ```bash
    docker-compose --env-file=.env.${ENV_NAME}.secrets run --rm terraform plan -var-file=terraform.${ENV_NAME}.tfvars
    ```

1. If everything looks good, run this command:

    ```bash
    docker-compose --env-file=.env.${ENV_NAME}.secrets run --rm terraform apply -var-file=terraform.${ENV_NAME}.tfvars
    ````
   Review the plan again, and answer `yes` when prompted.

## Uninstalling and deleting the broker

1. Delete any instances managed by the brokers. (This will prevent orphaning of backend resources.)
1. There's a safeguard in place to make sure you _really mean it_ before you delete the broker: Enable deletion of the databases by changing the `prevent_destroy` attribute in `broker/main.tf` from `true` to `false`.
1. Run Terraform destroy and answer `yes` when prompted.

```bash
docker-compose --env-file=.env.${ENV_NAME}.secrets run --rm terraform destroy -var-file=terraform.${ENV_NAME}.tfvars
```

## Continuously deploying the broker

This repository includes a GitHub Action that can continuously deploy the
`main` branch for you. To configure it, fork this repository in GitHub, then follow these steps.

### Create a workspace for the staging environment

Set up a new workspace in the Terraform state for the staging environment.

```bash
docker-compose run --rm terraform workspace new staging
```

### Set up global secrets (used for sharing the Terraform state)

Enter the following into [GitHub's `Settings > Secrets` page](/settings/secrets) on your fork:

| Secret Name | Description |
|-------------|-------------|
| AWS_ACCESS_KEY_ID | the S3 bucket key for Terraform state|
| AWS_SECRET_ACCESS_KEY | the S3 bucket secret for Terraform state |

### Set up environment secrets (used to deploy and configure the broker)

Create "staging" and "production" environments in [GitHub's `Settings > Environments` page](/settings/environments) on your fork. In each environment, enter the following secrets:

| Secret Name | Description |
|-------------|-------------|
| TF_VAR_AWS_ACCESS_KEY_ID | the key for brokering resources in AWS |
| TF_VAR_AWS_SECRET_ACCESS_KEY | the secret for brokering resources in AWS |
| TF_VAR_cf_username | the username for a Cloud Foundry user with `SpaceDeveloper` access to the target spaces |
| TF_VAR_cf_password | the password for a Cloud Foundry user with `SpaceDeveloper` access to the target spaces |

Finally, edit the `terraform.staging.tfvars` and `terraform.production.tfvars` files to supply the target orgs and spaces for the deployment.

Once these secrets are in place, the GitHub Action should be operational.

* Any pull-requests will
  1. test the Terraform format
  1. test the Terraform validity for the staging environment
  1. test the Terraform validity for the production environment
  1. post a summary of the planned changes for each environment on the pull-request
* Any merges to the `main` branch will
  1. deploy the changes to the staging environment
  1. run tests on the broker in the staging environment
  1. (if successful) deploy the changes to the production environment

#### AWS Accounts and Regions in use:

| SSB Environment | U.S. Notify Environments |AWS Account | AWS Region |
|-----------------|--------------------------|------------|------------|
| Production | prod | GovCloud prod | us-gov-west-1 |
| Staging | demo, staging, & sandbox | Commercial prod | us-west-2 |
| Development | sandbox | Commercial dev | us-west-2 |

## Force cleanup of orphaned resources

If the broker fails to provision or bind a service unexpectedly, Cloud Foundry's error-handling of the situation is not great. You might end up in a situation where the broker has provisioned resources or created a binding that Cloud Foundry doesn't know about. Or, you may find Cloud Foundry knows about the b0rked service (eg last operation shows "create failed"), but you're unable to `cf delete-service` without then landing in a "delete failed" state.

In those situations, don't panic. Here's how you can clean up!


1. Get the GUID for the problem service instance.

    ``` bash
    $ cf service <servicename> --guid
    ```

2. Get a shell going inside an application instance.

    ``` bash
    $ cf ssh ssb-<brokerpakname>
    $ /tmp/lifecycle/shell
    ```

3. If [this upstream bug](https://github.com/cloudfoundry-incubator/cloud-service-broker/issues/210) has not been fixed, make sure the client uses a URL-encoded version of the password.

    1. [URL-encode](https://www.google.com/search?q=url+encode) the value of the `SECURITY_USER_PASSWORD` environment variable, then

    2. Set that encoded result as the new value

           export SECURITY_USER_PASSWORD=${the-encoded-value}

4. Invoke the deprovision operation directly.

    ``` bash
    $ ./cloud-service-broker client deprovision --serviceid <serviceid> --planid <planid> --instanceid <instanceid>
    ```

    * The `instanceid` is the GUID you extracted in step 1.
    * The `serviceid` and `planid` are the GUIDs from the service catalog.

4. Log out of the SSH session

    ```bash
    $ exit
    ```

5. Locally, purge the Cloud Foundry-side record of the service

    ``` bash
    $ cf purge-service-instance <servicename>
    ```

6. Purge any resources that the broker provisioned which are now orphaned in the backend service. (For example, you may need to manually delete resources that were created in AWS.)

    The set of resources will vary by brokerpak and service/plan. See the README for the brokerpak for the appropriate steps to take.


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

## Troubleshooting

### Domain identity verification

```
Error creating SES domain identity verification
```
The error may say the verification is stuck in `Pending` or `Failed`.

This indicates AWS is unable to [verify a domain used for emailing](https://docs.aws.amazon.com/ses/latest/dg/creating-identities.html). This problem arises when provisioning resources with the [SMTP Brokerpak](https://github.com/GSA-TTS/datagov-brokerpak-smtp). It may be caused by a DNS misconfiguration.

Needed DNS records are described in the output of:
``` bash
docker-compose --env-file=.env.${ENV_NAME}.secrets run --rm terraform show
```
(The value of `ENV_NAME` comes from [&sect; Creating and installing the broker](#creating-and-installing-the-broker))

For more, refer to the [Troubleshooting section](https://github.com/GSA-TTS/datagov-brokerpak-smtp/tree/main/terraform/provision#troubleshooting) of the SMTP Brokerpak provisioning module.

### PR plan mismatch

Either of these errors indicate a mismatch between a Terraform `plan` created and stored when a pull request was first made, checked against the output when `plan` is run more recently:
* `Performing diff between the pull request plan and the plan generated at execution time`
* `Plan not found on PR`

This may be caused by a change in deployed resources or a change in Terraform's state that took place after a PR was first created. You could check that the CI/CD pipeline is still working by creating and merging a new, trivial PR.
