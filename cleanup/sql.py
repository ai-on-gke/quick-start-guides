from googleapiclient import discovery
from oauth2client.client import GoogleCredentials
from google.cloud import container_v1beta1


def gke_cluster_exists(subname: str, clusters: list) -> list:
    short_sha, build_id = subname.split("-")
    ci_clusters = list(filter(lambda cluster: short_sha in cluster.name and build_id in cluster.name, clusters))
    return ci_clusters

def delete_sql_instance(project_id, instance):
    credentials = GoogleCredentials.get_application_default()

    service = discovery.build('sqladmin', 'v1beta4', credentials=credentials)
    request = service.instances().delete(project=project_id, instance=instance)
    response = request.execute()
    print(response)


def run(project_id):
    credentials = GoogleCredentials.get_application_default()
    service = discovery.build('sqladmin', 'v1beta4', credentials=credentials)
    sql_request = service.instances().list(project=project_id)

    gke_client = container_v1beta1.ClusterManagerClient()
    gke_request = container_v1beta1.ListClustersRequest(
        project_id=project_id,
        zone="-",
    )
    gke_response = gke_client.list_clusters(request=gke_request)

    while sql_request is not None:
        sql_response = sql_request.execute()
        if not sql_response.get("items", None):
            return
        for database_instance in sql_response['items']:
            instance = database_instance["serverCaCert"]["instance"]
            if not instance.startswith("pgvector-instance-"):
                continue
            gke_cluster_name = gke_cluster_exists(instance[len("pgvector-instance-") + 1:], gke_response.clusters)
            if len(gke_cluster_name) == 0:
                delete_sql_instance(project_id, instance)
                print(f"Deleted sql instance: {instance}")
            else:
                print(f"Skip sql instance {instance}, since there is a GKE cluster: {gke_cluster_name}")

        sql_request = service.instances().list_next(previous_request=sql_request, previous_response=sql_response)