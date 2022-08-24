resource "kubernetes_persistent_volume_claim" "aws-efs-csi-driver-pvc" {
  metadata {
    name = "aws-efs-csi-driver-pvc"
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = var.storage_class
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    volume_name = "${kubernetes_persistent_volume.aws-efs-csi-driver-pv.metadata.0.name}"
  }
}

resource "kubernetes_persistent_volume" "aws-efs-csi-driver-pv" {
  metadata {
    name = "aws-efs-csi-driver-pv"
  }
  spec {
    capacity = {
      storage = "10Gi"
    }
    access_modes = ["ReadWriteMany"]
    storage_class_name = var.storage_class
    persistent_volume_source {
      csi {
        driver = "efs.csi.aws.com"
        volume_handle = var.efsVolume_id
      }
    }
  }
}
