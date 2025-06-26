import time
import re
from google.cloud import container_v1beta1
from datetime import datetime, timedelta


def filter_clusters(clusters, hours):
    ci_cluster = lambda name: re.match(r".*ml-.*-cluster$", name)

    def check_old_create_time(create_time):
        create_datetime = datetime.fromisoformat(create_time)
        now_datetime = datetime.now(create_datetime.tzinfo)
        time_difference = now_datetime - create_datetime
        return time_difference > timedelta(hours=hours)

    ci_clusters = list(filter(lambda cluster: ci_cluster(cluster.name), clusters))
    save_ci_clusters = list(filter(lambda cluster: not check_old_create_time(cluster.create_time), ci_clusters))
    sas_to_save = [cluster.node_config.service_account for cluster in save_ci_clusters]

    return list(filter(lambda cluster: check_old_create_time(cluster.create_time), ci_clusters)), sas_to_save


def run(project_id: str, hours: int):
    gke_client = container_v1beta1.ClusterManagerClient()

    request = container_v1beta1.ListClustersRequest(
        project_id=project_id,
        zone="-",
    )
    response = gke_client.list_clusters(request=request)
    clusters, sas_to_save = filter_clusters(response.clusters, hours)
    print(f"Clusters to delete: {len(clusters)}")
    for cluster in clusters:
        print(f"Start to delete cluster {cluster.name}")
        try:
            name = f"projects/{project_id}/locations/{cluster.zone}/clusters/{cluster.name}"
            request = container_v1beta1.DeleteClusterRequest(
                name=name,
            )
            delete_operation = gke_client.delete_cluster(request=request)
            print(f"Cluster {cluster.name} deletion initiated")
            start_time = time.time()
            while delete_operation.status != container_v1beta1.types.Operation.Status.DONE and time.time() - start_time < 1 * 60:
                print(f"{cluster.name}: delete_operation.status is not DONE")
                time.sleep(10)
            print(f"Cluster {cluster.name} in {cluster.zone} successfully deleted.")
        except Exception as e:
            print(f"Error while deleting cluster {cluster.name}: {e}")

    # Wait unitl all clusters are deleted
    start_time = time.time()
    while len(clusters) != 0 and time.time() - start_time < 20 * 60:
        timestamp = time.time() - start_time
        print(f"{len(clusters)} remains. {round(timestamp / 60)} minutes passed.")
        time.sleep(2*60)
        request = container_v1beta1.ListClustersRequest(
            project_id=project_id,
            zone="-",
        )
        response = gke_client.list_clusters(request=request)
        clusters = filter_clusters(response.clusters, hours)

    return sas_to_save
