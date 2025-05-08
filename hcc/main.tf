/**
  * Copyright 2023 Google LLC
  *
  * Licensed under the Apache License, Version 2.0 (the "License");
  * you may not use this file except in compliance with the License.
  * You may obtain a copy of the License at
  *
  *      http://www.apache.org/licenses/LICENSE-2.0
  *
  * Unless required by applicable law or agreed to in writing, software
  * distributed under the License is distributed on an "AS IS" BASIS,
  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  * See the License for the specific language governing permissions and
  * limitations under the License.
  */

data "google_client_config" "default" {}
data "google_project" "project" {
  project_id = var.project_id
}

locals {
  subnetwork_name = "${var.goog_cm_deployment_name}-gke-net"
  result_bucket_name = "${var.project_id}-${var.goog_cm_deployment_name}-result"
}

module "gke-a3-mega-net" {
  count = var.gpu_type == "A3 Mega"? 1 : 0
  source          = "./modules/embedded/modules/network/vpc"
  deployment_name = var.goog_cm_deployment_name
  project_id      = var.project_id
  region          = local.region != null ? local.region : error("Cannot find region for zone")
  secondary_ranges = {
    (local.subnetwork_name) = [{
      ip_cidr_range = "10.4.0.0/14"
      range_name    = "pods"
      }, {
      ip_cidr_range = "10.0.32.0/20"
      range_name    = "services"
    }]
  }
  subnetwork_name = local.subnetwork_name
}

module "gke-a3-mega-gpunets" {
  count = var.gpu_type == "A3 Mega"? 1 : 0
  source                  = "./modules/embedded/modules/network/multivpc"
  deployment_name         = var.goog_cm_deployment_name
  global_ip_address_range = "192.169.0.0/16"
  network_count           = 8
  network_name_prefix     = "${var.goog_cm_deployment_name}-gpunet"
  project_id              = var.project_id
  region          = local.region != null ? local.region : error("Cannot find region for zone")
  subnetwork_cidr_suffix  = 24
}

module "gke-a3-ultra-net-0" {
  count = var.gpu_type == "A3 Ultra"? 1 : 0
  source          = "./modules/embedded/modules/network/vpc"
  deployment_name = var.goog_cm_deployment_name
  firewall_rules = [{
    allow = [{
      ports    = ["0-65535"]
      protocol = "tcp"
      }, {
      ports    = ["0-65535"]
      protocol = "udp"
      }, {
      protocol = "icmp"
    }]
    name   = "${var.goog_cm_deployment_name}-internal-0"
    ranges = ["192.168.0.0/16"]
  }]
  labels       = var.labels
  network_name = "${var.goog_cm_deployment_name}-net-0"
  project_id   = var.project_id
  region       = local.region
  secondary_ranges_list = [{
    ranges = [{
      ip_cidr_range = "10.4.0.0/14"
      range_name    = "pods"
      }, {
      ip_cidr_range = "10.0.32.0/20"
      range_name    = "services"
    }]
    subnetwork_name = "${var.goog_cm_deployment_name}-sub-0"
  }]
  subnetworks = [{
    subnet_ip     = "192.168.0.0/18"
    subnet_name   = "${var.goog_cm_deployment_name}-sub-0"
    subnet_region = local.region
  }]
}

module "gke-a3-ultra-net-1" {
  count = var.gpu_type == "A3 Ultra"? 1 : 0
  source          = "./modules/embedded/modules/network/vpc"
  deployment_name = var.goog_cm_deployment_name
  firewall_rules = [{
    allow = [{
      ports    = ["0-65535"]
      protocol = "tcp"
      }, {
      ports    = ["0-65535"]
      protocol = "udp"
      }, {
      protocol = "icmp"
    }]
    name   = "${var.goog_cm_deployment_name}-internal-1"
    ranges = ["192.168.0.0/16"]
  }]
  labels       = var.labels
  mtu          = 8896
  network_name = "${var.goog_cm_deployment_name}-net-1"
  project_id   = var.project_id
  region       = local.region
  subnetworks = [{
    subnet_ip     = "192.168.64.0/18"
    subnet_name   = "${var.goog_cm_deployment_name}-sub-1"
    subnet_region = local.region
  }]
}

module "gke-a3-ultra-rdma-net" {
  count = var.gpu_type == "A3 Ultra"? 1 : 0
  source               = "./modules/embedded/modules/network/gpu-rdma-vpc"
  deployment_name      = var.goog_cm_deployment_name
  mtu                  = 8896
  network_name         = "${var.goog_cm_deployment_name}-rdma-net"
  network_profile      = "https://www.googleapis.com/compute/beta/projects/${var.project_id}/global/networkProfiles/${local.zone}-vpc-roce"
  network_routing_mode = "REGIONAL"
  project_id           = var.project_id
  region               = local.region
  subnetworks_template = {
    count       = 8
    ip_range    = "192.168.128.0/18"
    name_prefix = "${var.goog_cm_deployment_name}-rdma-sub"
    region      = local.region
  }
}

module "gke-a4-net-0" {
  count = var.gpu_type == "A4 High"? 1 : 0
  source          = "./modules/embedded/modules/network/vpc"
  deployment_name = var.goog_cm_deployment_name
  firewall_rules = [{
    allow = [{
      ports    = ["0-65535"]
      protocol = "tcp"
      }, {
      ports    = ["0-65535"]
      protocol = "udp"
      }, {
      protocol = "icmp"
    }]
    name   = "${var.goog_cm_deployment_name}-internal-0"
    ranges = ["192.168.0.0/16"]
  }]
  labels       = var.labels
  network_name = "${var.goog_cm_deployment_name}-net-0"
  project_id   = var.project_id
  region       = local.region
  secondary_ranges_list = [{
    ranges = [{
      ip_cidr_range = "10.4.0.0/14"
      range_name    = "pods"
      }, {
      ip_cidr_range = "10.0.32.0/20"
      range_name    = "services"
    }]
    subnetwork_name = local.subnetwork_name
  }]
  subnetworks = [{
    subnet_ip     = "192.168.0.0/18"
    subnet_name   = local.subnetwork_name
    subnet_region = local.region
  }]
}

module "gke-a4-net-1" {
  count = var.gpu_type == "A4 High"? 1 : 0
  source          = "./modules/embedded/modules/network/vpc"
  deployment_name = var.goog_cm_deployment_name
  firewall_rules = [{
    allow = [{
      ports    = ["0-65535"]
      protocol = "tcp"
      }, {
      ports    = ["0-65535"]
      protocol = "udp"
      }, {
      protocol = "icmp"
    }]
    name   = "${var.goog_cm_deployment_name}-internal-1"
    ranges = ["192.168.0.0/16"]
  }]
  labels       = var.labels
  network_name = "${var.goog_cm_deployment_name}-net-1"
  project_id   = var.project_id
  region       = local.region
  subnetworks = [{
    subnet_ip     = "192.168.64.0/18"
    subnet_name   = "${var.goog_cm_deployment_name}-sub-1"
    subnet_region = local.region
  }]
}

module "gke-a4-rdma-net" {
  count = var.gpu_type == "A4 High"? 1 : 0
  source               = "./modules/embedded/modules/network/gpu-rdma-vpc"
  deployment_name      = var.goog_cm_deployment_name
  network_name         = "${var.goog_cm_deployment_name}-rdma-net"
  network_profile      = "https://www.googleapis.com/compute/beta/projects/${var.project_id}/global/networkProfiles/${local.zone}-vpc-roce"
  network_routing_mode = "REGIONAL"
  project_id           = var.project_id
  region               = local.region
  subnetworks_template = {
    count       = 8
    ip_range    = "192.168.128.0/18"
    name_prefix = "${var.goog_cm_deployment_name}-rdma-sub"
    region      = local.region
  }
}

locals {
  cluster_machine_type_attributes = {
    "A3 Mega"  = {
      additional_networks  = var.gpu_type == "A3 Mega" ? flatten([module.gke-a3-mega-gpunets[0].additional_networks]) : []
      network_id           = try(one(module.gke-a3-mega-net).network_id, null)
      subnetwork_self_link = try(one(module.gke-a3-mega-net).subnetwork_self_link, null)
      version_prefix       = null
      maintenance_exclusions = [{
        end_time        = "2025-12-22T00:00:00Z"
        exclusion_scope = "NO_MINOR_OR_NODE_UPGRADES"
        name            = "no-minor-or-node-upgrades-indefinite-cluster-director-mega"
        start_time      = "2024-12-01T00:00:00Z"
      }]
    }
    "A3 Ultra" = {
      additional_networks  = var.gpu_type == "A3 Ultra" ? concat([{ network = module.gke-a3-ultra-net-1[0].network_name, subnetwork = module.gke-a3-ultra-net-1[0].subnetwork_name, subnetwork_project = var.project_id, nic_type = "GVNIC", queue_count = null, network_ip = null, stack_type = null, access_config = [{ nat_ip = null, public_ptr_domain_name = null, network_tier = null }], ipv6_access_config = [], alias_ip_range = [] }], module.gke-a3-ultra-rdma-net[0].subnetwork_interfaces_gke) : []
      network_id           = try(one(module.gke-a3-ultra-net-0).network_id, null)
      subnetwork_self_link = try(one(module.gke-a3-ultra-net-0).subnetwork_self_link, null)
      version_prefix       = "1.32."
      maintenance_exclusions = [{
        end_time        = "2025-12-22T00:00:00Z"
        exclusion_scope = "NO_MINOR_OR_NODE_UPGRADES"
        name            = "no-minor-or-node-upgrades-indefinite-cluster-director-ultra"
        start_time      = "2024-12-01T00:00:00Z"
      }]
    }
    "A4 High"  = {
      additional_networks  = var.gpu_type == "A4 High" ? flatten([{ network = module.gke-a4-net-1[0].network_name, subnetwork = module.gke-a4-net-1[0].subnetwork_name, subnetwork_project = var.project_id, nic_type = "GVNIC", queue_count = null, network_ip = null, stack_type = null, access_config = [{ nat_ip = null, public_ptr_domain_name = null, network_tier = null }], ipv6_access_config = [], alias_ip_range = [] }, module.gke-a4-rdma-net[0].subnetwork_interfaces_gke]) : []
      network_id           = try(one(module.gke-a4-net-0).network_id, null)
      subnetwork_self_link = try(one(module.gke-a4-net-0).subnetwork_self_link, null)
      version_prefix       = "1.32."
      maintenance_exclusions = [{
        end_time        = "2025-12-22T00:00:00Z"
        exclusion_scope = "NO_MINOR_OR_NODE_UPGRADES"
        name            = "no-minor-or-node-upgrades-indefinite-cluster-director-a4high"
        start_time      = "2024-12-01T00:00:00Z"
      }]
    }
  }

  nodepool_machine_type_attributes = {
    "A3 Mega"  = {
      machine_type         = "a3-megagpu-8g"
      additional_networks  = var.gpu_type == "A3 Mega" ? flatten([module.gke-a3-mega-gpunets[0].additional_networks]) : []
      guest_accelerator    = [{
        count = 8
        gpu_driver_installation_config = {
	  gpu_driver_version = "LATEST"
	}
        type = "nvidia-h100-mega-80gb"
      }]
      local_ssd_count_ephemeral_storage = 16
      reservation_affinity = {
          consume_reservation_type = "SPECIFIC_RESERVATION"
          specific_reservations = [{
            name = var.reservation
            project = var.project_id
          }]
      }
      placement_policy = {
        type = "COMPACT"
        name = var.placement_policy_name
      }
      host_maintenance_interval = "PERIODIC"
      internal_ghpc_module_id           = "a3-megagpu-pool"
    }
    "A3 Ultra" = {
      machine_type         = "a3-ultragpu-8g"
      additional_networks  = var.gpu_type == "A3 Ultra" ? concat([{ network = module.gke-a3-ultra-net-1[0].network_name, subnetwork = module.gke-a3-ultra-net-1[0].subnetwork_name, subnetwork_project = var.project_id, nic_type = "GVNIC", queue_count = null, network_ip = null, stack_type = null, access_config = [{ nat_ip = null, public_ptr_domain_name = null, network_tier = null }], ipv6_access_config = [], alias_ip_range = [] }], module.gke-a3-ultra-rdma-net[0].subnetwork_interfaces_gke) : []
      guest_accelerator    = [{
        count = 8
        gpu_driver_installation_config = {
	  gpu_driver_version = "LATEST"
	}
        type = "nvidia-h200-141gb"
      }]
      local_ssd_count_ephemeral_storage = 32
      reservation_affinity = {
          consume_reservation_type = "SPECIFIC_RESERVATION"
          specific_reservations = [{
            name = var.reservation_block == "" ? var.reservation : "${var.reservation}/reservationBlocks/${var.reservation_block}"
            project = var.project_id
          }]
      }
      placement_policy     = {
        type = null
      }
      host_maintenance_interval = null
      internal_ghpc_module_id           = "a3-ultragpu-pool"
    }
    "A4 High"  = {
      machine_type         = "a4-highgpu-8g"
      additional_networks  = var.gpu_type == "A4 High" ? flatten([{ network = module.gke-a4-net-1[0].network_name, subnetwork = module.gke-a4-net-1[0].subnetwork_name, subnetwork_project = var.project_id, nic_type = "GVNIC", queue_count = null, network_ip = null, stack_type = null, access_config = [{ nat_ip = null, public_ptr_domain_name = null, network_tier = null }], ipv6_access_config = [], alias_ip_range = [] }, module.gke-a4-rdma-net[0].subnetwork_interfaces_gke]) : []
      guest_accelerator = [{
        count = 8
        gpu_driver_installation_config = {
	  gpu_driver_version = "LATEST"
	}
        type = "nvidia-b200"
      }]
      local_ssd_count_ephemeral_storage = 32
      reservation_affinity = {
          consume_reservation_type = "SPECIFIC_RESERVATION"
          specific_reservations = [{
            name = var.reservation_block == "" ? var.reservation : "${var.reservation}/reservationBlocks/${var.reservation_block}"
            project = var.project_id
          }]
      }
      placement_policy     = {
        type = null
      }
      host_maintenance_interval = null
      internal_ghpc_module_id           = "a4-highgpu-pool"
    }
  }
}

module "gke-cluster" {
  source                  = "./modules/embedded/modules/scheduler/gke-cluster"

  # Machine-type dependent attributes
  additional_networks     = local.cluster_machine_type_attributes[var.gpu_type].additional_networks
  network_id              = local.cluster_machine_type_attributes[var.gpu_type].network_id
  subnetwork_self_link    = local.cluster_machine_type_attributes[var.gpu_type].subnetwork_self_link
  version_prefix          = local.cluster_machine_type_attributes[var.gpu_type].version_prefix
  maintenance_exclusions  = local.cluster_machine_type_attributes[var.gpu_type].maintenance_exclusions

  deployment_name         = var.goog_cm_deployment_name # this will be the cluster name
  enable_dcgm_monitoring  = true
  enable_gcsfuse_csi      = true
  enable_private_endpoint = false
  labels                  = var.labels
  master_authorized_networks = [{
    cidr_block   = var.authorized_cidr
    display_name = "kubectl-access-network"
  }]
  project_id                    = var.project_id
  region                        = local.region
  zone                          = local.zone
  release_channel               = "RAPID"
  system_node_pool_disk_size_gb = 200
  system_node_pool_machine_type = "e2-standard-16"
  system_node_pool_taints       = []
}

module "gke-gpu-nodepool" {
  source              = "./modules/embedded/modules/compute/gke-node-pool"

  # Machine-type dependent attributes
  machine_type                      = local.nodepool_machine_type_attributes[var.gpu_type].machine_type
  additional_networks               = local.nodepool_machine_type_attributes[var.gpu_type].additional_networks
  guest_accelerator                 = local.nodepool_machine_type_attributes[var.gpu_type].guest_accelerator
  local_ssd_count_ephemeral_storage = local.nodepool_machine_type_attributes[var.gpu_type].local_ssd_count_ephemeral_storage
  reservation_affinity              = local.nodepool_machine_type_attributes[var.gpu_type].reservation_affinity
  placement_policy                  = local.nodepool_machine_type_attributes[var.gpu_type].placement_policy
  host_maintenance_interval         = local.nodepool_machine_type_attributes[var.gpu_type].host_maintenance_interval
  internal_ghpc_module_id           = local.nodepool_machine_type_attributes[var.gpu_type].internal_ghpc_module_id

  auto_upgrade        = true
  cluster_id          = module.gke-cluster.cluster_id
  gke_version         = module.gke-cluster.gke_version
  labels              = var.labels
  project_id          = var.project_id
  static_node_count   = local.node_count
  zones               = [local.zone]
}

module "workload-manager-install" {
  source = "./modules/embedded/modules/management/kubectl-apply"
  cluster_id = module.gke-cluster.cluster_id
  jobset = {
    install = true
    version = "v0.7.2"
  }
  kueue = {
    install = true
    config_path = "./kueue/kueue-configuration.yaml.tftpl"
    config_template_vars = {
      node_pool_name = module.gke-gpu-nodepool.node_pool_names[0]
      num_gpus       = module.gke-gpu-nodepool.static_gpu_count
    }
    version = "v0.10.0"
  }
  project_id = var.project_id
}

# created by replicating the helm install in https://github.com/AI-Hypercomputer/gpu-recipes/tree/main/training/a3mega/llama-3-70b/nemo-pretraining-gke
module "nemo" {
  count = local.recipe != "gke"? 1 : 0
  source     = "./modules/nemo"
  cluster_id = module.gke-cluster.cluster_id
  checkpoint_bucket = local.result_bucket_name
  recipe = local.recipe
  node_count = local.node_count
  gpu_type = var.gpu_type
  queue = "user-queue"
  # Providers needs to be explicitely passed in when a depends_on is present in a module.
  providers = {
    helm = helm
  }
  # The kueue install needs to finished completely or else the deployment of nemo workload throws error, thus adding the depends_on for workload-manager-install.
  # The k8s networks are created in the cluster module and deletion of network will fail if there are pods still depending on it, thus adding the depends_on for gke-cluster.
  depends_on = [module.workload-manager-install, module.gke-cluster]
}

module "gcs" {
  source     = "./modules/gcs"
  project_id = var.project_id
  region          = local.region != null ? local.region : error("Cannot find region for zone")
  bucket_name     = local.result_bucket_name
}

resource "google_storage_bucket_iam_binding" "result_bucket_viewer" {
  bucket = local.result_bucket_name
  role   = "roles/storage.objectUser"
  members = [
    "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/default/sa/default",
  ]
  depends_on = [module.gcs]
}
