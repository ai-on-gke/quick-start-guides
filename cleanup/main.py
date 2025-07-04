import functions_framework
import vpc, gke, sa, vertex, sql, gcs, iam


@functions_framework.http
def vpc_cleanup(request):
    """HTTP Cloud Function.
    Args:
        request (flask.Request): The request object.
        <https://flask.palletsprojects.com/en/1.1.x/api/#incoming-request-data>
    Returns:
        The response text, or any set of values that can be turned into a
        Response object using `make_response`
        <https://flask.palletsprojects.com/en/1.1.x/api/#flask.make_response>.
    """
    project_id = "ai-on-gke-qss"
    hours = 4
    sas_to_save = gke.run(project_id, hours)
    sa.run(project_id, sas_to_save)
    vpc.run(project_id, hours)
    vertex.run(project_id)
    sql.run(project_id)
    gcs.run(hours)
    iam.run(project_id)
    return "done"