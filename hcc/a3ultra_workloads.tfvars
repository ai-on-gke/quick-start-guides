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

authorized_cidr = "0.0.0.0/0"

goog_cm_deployment_name = "ultra-cluster-test"

labels = {
  created-by="gke-ai-quick-start-solutions"
  gke_product_type="cluster-director-qss"
}

project_id = "gke-aishared-gsc-dev"

a3_mega_zone = ""
a3_ultra_zone = "europe-west1-b"
a4_high_zone = ""

node_count_gke_nccl = 2
node_count_gke = -1
node_count_nemo = -1
node_count_maxtext = -1
node_count_llama_3_7b = -1

# A3 Ultra recipe options:
# - "gke"
# - "gke-nccl"
# - "llama3.1_7b_nemo_pretraining"
# - "llama3.1_70b_nemo_pretraining"
# - "llama3.1_70b_maxtext_pretraining"
# - "mixtral8_7b_nemo_pretraining"
# - "mixtral8_7b_maxtext_pretraining"
a3ultra_recipe = "gke-nccl"
a3mega_recipe=""
a4high_recipe=""

reservation = "nvidia-h200-b4nm5gd6nxkdw"
reservation_block = ""
placement_policy_name = ""

gpu_type = "A3 Ultra"
a3_ultra_consumption_model = "Reservation"
a3_mega_consumption_model = ""
a4_high_consumption_model = ""
