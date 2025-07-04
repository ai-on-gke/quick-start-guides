from google.cloud import iam_admin_v1


def filter_sas(sas: list, project_id: str, sas_to_save: list):
    ci_sa = lambda name: name.startswith(f"projects/{project_id}/serviceAccounts/tf-gke-ml-")
    sa_in_use = lambda name: name in sas_to_save
    return list(filter(lambda sa: ci_sa(sa.name) and not sa_in_use(sa.name), sas))


def run(project_id: str, sas_to_save: list):
    iam_admin_client = iam_admin_v1.IAMClient()
    request = iam_admin_v1.ListServiceAccountsRequest(
        name=f"projects/{project_id}"
    )
    response = iam_admin_client.list_service_accounts(request=request)
    sas = filter_sas(response.accounts, project_id, sas_to_save)
    print(f"Service accounts to delete: {len(sas)}")
    for sa in sas:
        sa_name = sa.name.split('/')[-1]
        print(f"Start to delete service account {sa_name}")
        try:
            request = iam_admin_v1.DeleteServiceAccountRequest(name=sa.name)
            iam_admin_client.delete_service_account(request=request)
            print(f"Deleted a service account: {sa_name}")
        except Exception as e:
            print(f"Error while deleting {sa_name}: {e}")