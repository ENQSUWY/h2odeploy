# Terraform recipe for spinning up Model Management components in AWS EKS

## Prerequisites

- [Terraform](https://www.terraform.io/) (`>=0.13`)
- Access to AWS (this generally means the `~/.aws/config` and `~/.aws/credentials` files are present on your local machine)
- The domain name specified in the `config.tfvars` configuration file below needs to be registered with [Route53](https://aws.amazon.com/route53/)
- The ability to create a new [VPC](https://aws.amazon.com/vpc/) in the region specified in the `aws.tf` configuration file below
- A valid Driverless AI licence key file at this location on your local machine: `~/.driverlessai/license.sig`
- [Docker](https://www.docker.com/) running locally with access to the docker images specified in the `config.tfvars` configuration file below

## Configuration for pure AWS Deployments

Note:  For this deployment style, Terraform will create the EKS cluster for you.

1.  Create the file `aws.tf` and copy and paste the following:

  ```terraform
  # aws.tf example

  provider "aws" {
    region  = "us-east-1"
  }
  ```

  1.1.  (OPTIONAL) Change the region in the example.

  Known supported regions include:

  - us-east-1
  - us-west-2
  - eu-west-3
  - eu-central-1

  Known regions **_not supported_** include:

  - us-west-1

  [ Note:  Terraform documentation for the AWS Provider configuration file is [here](https://www.terraform.io/docs/providers/aws/index.html). ]

2.  Create the file `config.auto.tfvars` and copy and paste the following:

  ```terraform
  # config.auto.tfvars example

  #-------------------
  # Required settings
  #-------------------

  domain = "<DOMAIN_NAME>"

  deployer_image                = "h2oai/deployer:<VERSION>"
  drift_detection_trigger_image = "h2oai/h2oai-drift-trigger:<VERSION>"
  drift_detection_worker_image  = "h2oai/h2oai-drift-worker:<VERSION>"
  driverless_image              = "gcr.io/vorvan/h2oai/dai-centos7-x86_64:1.9.0-cuda10.0-<VERSION>.jenkins"
  model_ingestion_image         = "h2oai/h2oai-model-ingest:<VERSION>"
  monitor_proxy_image           = "h2oai/monitor-proxy:<VERSION>"
  security_proxy_image          = "h2oai/h2oai-security-proxy:<VERSION>"
  scorer_image                  = "h2oai/rest-scorer:<VERSION>"
  storage_image                 = "h2oai/h2oai-storage:<VERSION>"
  studio_image                  = "h2oai/studio:<VERSION>"
  ui_image                      = "h2oai/h2oai-storage-web:<VERSION>"


  # Specify volume sizes (in GiB) for Driverless AI, shared storage, and model monitoring.
  # Increase these values for production deployments.
  driverless_data_volume_size = 100
  storage_data_volume_size    = 100
  influxdb_data_volume_size   = 100

  #-------------------
  # Optional settings
  #-------------------

  eks_node_count          = 1
  eks_node_instance_type  = "m5.4xlarge"
  driverless_count        = 1
  driverless_license_path = "license.sig"
  prefix                  = "mop"
  studio_access_mode      = "production"
```

  2.1 Change the domain name in the example.

  2.2 Fix the image versions in the example.

  2.3 (OPTIONAL) Adjust the volume sizes in the example.

  2.4 (OPTIONAL) Change the EKS node count.

  2.5 (OPTIONAL) Change the EKS node instance type.

  [ Note:  See the included `variables.tf` file for a description of the specific variables used by this deployment.  See the Terraform documentation for a [tfvars file](Terraform documentation for the https://www.terraform.io/docs/configuration/variables.html#variable-definitions-tfvars-files) for general information on how the file is structured. ]

  [ Note:  Advanced users may wish to use [other means](https://www.terraform.io/docs/configuration/variables.html) to set the variables. ]

## Configuraton for On-prem or Pre-existing Kubernetes-in-cloud deployments

This approach can work for most Kubernetes environments, but requires more configuration and networking knowledge.

The `platform_deployment_type` variable controls how users reach the services.  Two deployment types are supported:  `subdomain` and `node_port`.

`node_port` deployments are the least secure but most straightforward.  Set the domain to one of the IP addresses of the user-reachable worker nodes in your Kubernetes cluster.

`subdomain` deployments require that you setup DNS entries for the following, and that the traefik service is reachable by those DNS entries (typically by a LoadBalancer).  The following DNS entries are used:

* driverless-01.prefix.domain
* grafana.prefix.domain
* keycloak.prefix.domain
* model.prefix.domain
* studio.prefix.domain
* ui.prefix.domain

For advanced deployments, HTTPS can be configured, but it is recommended you start without it.

1.  Create the file `config.auto.tfvars` and copy and paste the following:

  ```terraform
  # config.auto.tfvars example

  #-------------------
  # Required settings
  #-------------------

  domain = "1.2.3.4"

  deployer_image                = "h2oai/deployer:<VERSION>"
  drift_detection_trigger_image = "h2oai/h2oai-drift-trigger:<VERSION>"
  drift_detection_worker_image  = "h2oai/h2oai-drift-worker:<VERSION>"
  driverless_image              = "gcr.io/vorvan/h2oai/dai-centos7-x86_64:1.9.0-cuda10.0-<VERSION>.jenkins"
  model_ingestion_image         = "h2oai/h2oai-model-ingest:<VERSION>"
  monitor_proxy_image           = "h2oai/monitor-proxy:<VERSION>"
  security_proxy_image          = "h2oai/h2oai-security-proxy:<VERSION>"
  scorer_image                  = "h2oai/rest-scorer:<VERSION>"
  storage_image                 = "h2oai/h2oai-storage:<VERSION>"
  studio_image                  = "h2oai/studio:<VERSION>"
  ui_image                      = "h2oai/h2oai-storage-web:<VERSION>"

  # Specify volume sizes (in GiB) for Driverless AI, shared storage, and model monitoring.
  # Increase these values for production deployments.
  driverless_data_volume_size = 100
  storage_data_volume_size    = 100
  influxdb_data_volume_size   = 100

  #-------------------
  # Optional settings
  #-------------------

  driverless_count         = 1
  driverless_license_path  = "license.sig"
  platform_deployment_type = "node_port"
  prefix                   = "mop"
  protocol                 = "http"

  # You can manually specify the traefik service type if you have a reason to.
  # This is only useful if you are using subdomain DNS entries to reach the services.
  #
  # traefik_ingress_service_type = "LoadBalancer"

  # If you already have an nginx or other ingress with a load balancer, you can use
  # that instead of traefik.  This is done by changing the ingress class to nginx
  # (or something else).  This overrides the annotation kubernetes.io/ingress.class.
  #
  # kubernetes_io_ingress_class = "nginx"
```

  1.1  Change the domain address in the example to the correct hardcoded IP address (for `node_port` deployments) or to the correct domain name (for `subdomain` deployments).

  1.2  Fix the image versions in the example.

  1.3 (OPTIONAL) Adjust the volume sizes in the example.

  1.4  Comment out the module `eks_cluster` in `main.tf`.  Comment out the eks outputs in `outputs.tf`.

  1.5  Modify the provider `kubernetes` in `main.tf` to:

  ```
  provider "kubernetes" {
      load_config_file = true
  }
```

## How to Deploy

Use `terraform` to deploy the software:

1. Initialize terraform workspace:

  ```
  terraform init
  ```

2. Make sure you have a valid Driverless AI license in `~/.driverlessai/license.sig`

3. (OPTIONAL) Review the actions terraform will take before applying them:

  ```
  terraform plan
  ```

4. Deploy:

  ```
  terraform apply
  ```

  Note:  It is common to get an `Unauthorized` error 15 minutes into
the terraform apply.  This is because by default terraform uses a credential with a 15 minute expiration.  Re-run the terraform apply command to pick up where it left off.

For reference, here are documentation links for the above terraform steps:

* [`terraform init`](https://www.terraform.io/docs/commands/init.html)
* [`terraform plan`](https://www.terraform.io/docs/commands/plan.html)
* [`terraform apply`](https://www.terraform.io/docs/commands/apply.html)


5. Create users in Keycloak

Authentication for H2O.ai software is backed by [Keycloak](https://www.keycloak.org/).  (Note the realm name is set to the `prefix` variable.)

- View the keycloak address by executing:

  ```sh
  terraform output keycloak_service
  ```

- The administrator account is `admin`
- View the administrator password by executing:

  ```sh
  terraform output keycloak_admin_password
  ```

For reference,the Keycloak user administration documentation is here:

* <https://www.keycloak.org/docs/8.0/server_admin/index.html#user-management>
