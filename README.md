# datagov-ssb

The Supplementary Service Broker (SSB) manages the lifecycle of services, filling gaps in [cloud.gov](https://cloud.gov)'s brokered services. The SSB is compliant with the [Open Service Broker API](https://www.openservicebrokerapi.org/) specification. Using this API, the service broker advertises a catalog of service offerings and service plans, and interprets calls for provision (create), bind, unbind, and deprovision (delete). What the broker does with each call can vary between services. In general, `provision` reserves resources on a service and `bind` delivers information to an app necessary for accessing the resource. The reserved resource is called a service instance.

What a service instance represents can vary by service, for example a single database on a multi-tenant server, a dedicated cluster, or even just an account on a web app. Clients, often platforms in their own right, interact with the SSB to provision and manage instances of the services offered. The broker provides all the information that an application or container needs to connect to the service instance, regardless of how or where the service is running.

The SSB can also be used from the command-line with [`eden`](https://github.com/starkandwayne/eden), or integrated into other platforms that make use of the [OSBAPI](https://www.openservicebrokerapi.org).

The SSB currently provides [SMTP](https://github.com/GSA/datagov-brokerpak-smtp), [Solr](https://github.com/GSA/datagov-brokerpak), and [(limited) Kubernetes](https://github.com/GSA/eks-brokerpak) services.
 
Services are defined in a
[brokerpaks](https://github.com/pivotal/cloud-service-broker/blob/master/docs/brokerpak-intro.md),
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
   into the respective `/app` directories.

    ```bash
    ./app-setup-eks.sh
    ./app-setup-smtp.sh
    ./app-setup-solr.sh
    ```

1. Copy the `backend.tfvars-template` and edit in the non-sensitive values for the S3 bucket.

    ```bash
    cp backend.tfvars-template backend.tfvars
    ${EDITOR} backend.tfvars
    ```

1. Copy the `.backend.secrets-template` and edit in the sensitive values for the S3 bucket.

    ```bash
    cp .backend.secrets-template .backend.secrets
    ${EDITOR} .backend.secrets
    ```

1. Set a variable with the name of the environment you want to work with

    ```bash
    export ENV_NAME=[environment_name]
    ```

1. Copy the `terraform.tfvars-template` and edit in any variable customizations for the target environment.

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

1. Run Terraform init to set up the backend.

    ```bash
    docker-compose --env-file .backend.secrets run --rm terraform init -backend-config backend.tfvars
    ```

1. Create a Terraform workspace for your environment and switch to it

    ```bash
    docker-compose --env-file=.backend.secrets run --rm terraform workspace new ${ENV_NAME}
    docker-compose --env-file=.backend.secrets run --rm terraform workspace select ${ENV_NAME}    
    ```

1. Run Terraform apply, review the plan, and answer `yes` when prompted.

    ```bash
    docker-compose --env-file=.env.${ENV_NAME}.secrets run --rm terraform apply -var-file=terraform.${ENV_NAME}.tfvars
    ```

## Uninstalling and deleting the broker

Run Terraform destroy and answer `yes` when prompted.

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
