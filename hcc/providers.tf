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

provider "google" {
  project = var.project_id
  region  = local.region
  zone    = local.zone
}

provider "google-beta" {
  project = var.project_id
  region  = local.region
  zone    = local.zone
}

locals {
  # Although we can infer cluster_name and cluster_location from input variables, terraform plan
  # will throws cluster not found error since it has not been created yet. Instead, we use the
  # cluster_id output from clutser modules to create the implicit dependency.
  cluster_id_parts = split("/", module.gke-cluster.cluster_id)
  cluster_name     = local.cluster_id_parts[5]
  cluster_location = local.cluster_id_parts[3]
}

data "google_container_cluster" "gke_cluster" {
  project  = var.project_id
  name     = local.cluster_name
  location = local.cluster_location
}

provider "helm" {
  kubernetes {
    host                   = data.google_container_cluster.gke_cluster.endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.gke_cluster.master_auth[0].cluster_ca_certificate)
  }
}

