# Kubernetes Application
# * Namespace
# * Pod
# * Service
#

resource "kubernetes_namespace" "rs-desafio-ns" {
  metadata {
    name = "${var.namespace_name}"
    labels {
      app = "nginx"
    }
    annotation {
      name = "example-annotation"
    }
  }
}

resource "kubernetes_pod" "rs-desafio-pod" { 
  metadata { 
    name  = "${var.nginx_pod_name}"
    namespace = "${var.namespace_name}"
    labels {
      app = "nginx"
    }
  }
  spec {
    container { 
      name = "${var.nginx_pod_name}"
      image = "${var.nginx_imagem_name}"
    }
  }
}

resource "kubernetes_service" "rs-desafio-service" { 
  metadata {
    name = "${var.nginx_pod_name}"
    namespace = "${var.namespace_name}"
  }
  spec{
    selector { 
      app = "${kubernetes_pod.rs-desafio-pod.metadata.0.labels.app}"
    }
    port {
      port = 8080
      target_port = 80
    }
    type = "LoadBalancer"
  }
}
