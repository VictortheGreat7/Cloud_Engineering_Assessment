# This script provisions the Kubernetes resources needed for the time API application.

# This resource creates a ConfigMap in the Kubernetes cluster.
# A ConfigMap is used to store non-confidential data in key-value pairs.
# ConfigMaps are used to decouple environment-specific configuration from the container images, allowing for more flexible deployments.
# The time zone is set to UTC, but this can be changed as needed.
resource "kubernetes_config_map_v2" "time_api_config" {
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

resource "helm_release" "namecom_webhook" {
  name       = "namecom-webhook"
  repository = "../webhook/deploy"
  chart      = "cert-manager-webhook-namecom"
  namespace  = "cert-manager"

  depends_on = [helm_release.cert_manager]
}


resource "kubernetes_secret_v2" "namecom_api_token" {
  metadata {
    name      = "namedotcom-credentials"
    namespace = "cert-manager"
  }

  data = {
    api-token = var.namecom_token
  }

  type = "Opaque"

  depends_on = [helm_release.namecom_webhook]
}

resource "helm_release" "cert_manager_issuers" {
  chart      = "cert-manager-issuers"
  name       = "cert-manager-issuers"
  version    = "0.3.0"
  repository = "https://charts.adfinis.com"
  namespace  = "cert-manager"

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
              webhook:
                groupName: acme.name.com
                solverName: namedotcom
                config:
                  username: "${var.namecom_username}"
                  apitokensecret:
                    name: namedotcom-credentials
                    key: api-token               
EOT
  ]

  depends_on = [helm_release.cert_manager, kubernetes_secret_v2.namecom_api_token]
}
