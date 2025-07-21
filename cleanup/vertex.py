from google.api_core.exceptions import FailedPrecondition, NotFound
from google.cloud import container_v1beta1
from google.cloud.iam_admin_v1.services.iam.pagers import ListRolesPager
from google.cloud.iam_admin_v1 import (
    DeleteRoleRequest,
    IAMClient,
    Role,
    UndeleteRoleRequest,
    ListRolesRequest,
    RoleView,
)


def check_adk_vertex_clusters(clusters) -> int:
    check_ci_cluster = lambda name: re.match(r".*ml-adk-vertex-.*-cluster$", name)
    ci_clusters = list(filter(lambda cluster: check_ci_cluster(cluster.name), clusters))
    return len(ci_clusters)


def delete_role(project_id: str, role_name: str) -> Role:
    """Deletes iam role in GCP project. Can be undeleted later.
    Args:
        project_id: GCP project id
        role_name: "projects/{project_id}/roles/{role_id}"

    Returns: google.cloud.iam_admin_v1.Role object
    """
    client = IAMClient()

    request = DeleteRoleRequest(name=role_name)
    try:
        role = client.delete_role(request)
        print(f"Deleted role: {role}")
        return role
    except NotFound:
        print(f"Role with id [{role_id}] not found, take some actions")
    except FailedPrecondition as err:
        print(f"Role with id [{role_id}] already deleted, take some actions)", err)


def run(
    project_id: str, show_deleted: bool = False, role_view: RoleView = RoleView.FULL
) -> ListRolesPager:
    """Deletes tutorialVertexAICustomRole roles in a GCP project.

    Args:
        project_id: GCP project ID
        show_deleted: Whether to include deleted roles in the results
        role_view: Level of detail for the returned roles (e.g., BASIC or FULL)

    Returns: A pager for traversing through the roles
    """
    gke_client = container_v1beta1.ClusterManagerClient()

    request = container_v1beta1.ListClustersRequest(
        project_id=project_id,
        zone="-",
    )
    response = gke_client.list_clusters(request=request)
    if check_adk_vertex_clusters(response.clusters) != 0:
        print("There are clusters that use this role.")
        return

    client = IAMClient()
    parent = f"projects/{project_id}"
    request = ListRolesRequest(parent=parent, show_deleted=show_deleted, view=role_view)
    roles = client.list_roles(request)
    role_template = "VertexAI Tutorial Custom Role"
    for page in roles.pages:
        for role in page.roles:
            if role.title[:len(role_template)] == role_template:
                delete_role(project_id, role.name)
    print("The role deletion is completed.")
