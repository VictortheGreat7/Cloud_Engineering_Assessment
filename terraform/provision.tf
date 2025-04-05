# This script provisions the Kubernetes resources needed for the time API application.

# This resource creates a ConfigMap in the Kubernetes cluster.
# A ConfigMap is used to store non-confidential data in key-value pairs.
# ConfigMaps are used to decouple environment-specific configuration from the container images, allowing for more flexible deployments.
# The time zone is set to UTC, but this can be changed as needed.
resource "kubernetes_config_map" "time_api_config" {
  metadata {
    name = "time-api-config"
  }

  data = {
    TIME_ZONE = "UTC"
  }

  depends_on = [azurerm_kubernetes_cluster.time_api_cluster]
}

# This module deploys the NGINX Ingress Controller to the Kubernetes cluster.
# It provides a way to expose HTTP and HTTPS routes from outside the cluster to the appropriate service based on the defined rules.
module "nginx-controller" {
  source  = "terraform-iaac/nginx-controller/helm"
  version = ">=2.3.0"

  depends_on = [azurerm_kubernetes_cluster.time_api_cluster]
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.5.4"

  create_namespace = true
  namespace        = "cert-manager"

  set {
    name  = "installCRDs"
    value = "true"
  }

  timeout = 600

  depends_on = [module.nginx-controller]
}

resource "time_sleep" "wait_for_crds" {
  create_duration = "5s"

  depends_on = [helm_release.cert_manager]
}

resource "helm_release" "cert_manager_issuers" {
  chart      = "cert-manager-issuers"
  name       = "cert-manager-issuers"
  version    = "0.3.0"
  repository = "https://charts.adfinis.com"

  values = [
    <<-EOT
clusterIssuers:
  - name: certmanager
    spec:
      acme:
        email: "greatvictor.anjorin@gmail.com"
        server: "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef:
          name: certmanager
        solvers:
          - dns01:
              azureDNS:
                resourceGroupName: "${azurerm_dns_zone.mywonder_works.resource_group_name}"
                subscriptionID: "d31507f4-324c-4bd1-abe1-5cdf45cba77d"
                hostedZoneName: "${azurerm_dns_zone.mywonder_works.name}"
                environment: AzurePublicCloud
                managedIdentity:
                  clientID: "${data.azurerm_kubernetes_cluster.time_api_cluster.kubelet_identity[0].object_id}"
EOT
  ]

  depends_on = [helm_release.cert_manager, time_sleep.wait_for_crds]
}
