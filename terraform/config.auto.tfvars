# config.auto.tfvars example

#-------------------
# Required settings
#-------------------

domain = "52-190-40-228.h2o.sslip.io"

deployer_image                = "h2oai/deployer:0.40.1"
drift_detection_trigger_image = "h2oai/h2oai-drift-trigger:0.40.1"
drift_detection_worker_image  = "h2oai/h2oai-drift-worker:0.40.1"
driverless_image              = "gcr.io/vorvan/h2oai/dai-centos7-x86_64:1.9.0-cuda10.0-0.40.1.jenkins"
model_ingestion_image         = "h2oai/h2oai-model-ingest:0.40.1"
gateway_image                 = "h2oai/mlops-grpc-gateway:0.40.1"
model_fetcher_image           = "h2oai/h2oai-model-fetcher:0.40.1"
monitor_proxy_image           = "h2oai/monitor-proxy:0.40.1"
security_proxy_image          = "h2oai/h2oai-security-proxy:0.40.1"
scorer_image                  = "h2oai/rest-scorer:0.40.1"
storage_image                 = "h2oai/h2oai-storage:0.40.1"
studio_image                  = "h2oai/studio:0.1.6"
ui_image                      = "h2oai/h2oai-storage-web:0.40.1"

# Specify volume sizes (in GiB) for Driverless AI, shared storage, and model monitoring.
# Increase these values for production deployments.
driverless_data_volume_size = 20
storage_data_volume_size    = 20
influxdb_data_volume_size   = 20

#-------------------
# Optional settings
#-------------------

namespace               = "mlops"
driverless_count         = 1
driverless_license_path  = "license.sig"
platform_deployment_type = "subdomain"
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
kubernetes_io_ingress_class = "nginx"