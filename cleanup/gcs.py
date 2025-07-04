from datetime import datetime, timedelta
from google.cloud import storage


def check_old_create_time(create_datetime, hours):
    now_datetime = datetime.now(create_datetime.tzinfo)
    time_difference = now_datetime - create_datetime
    return time_difference > timedelta(hours=hours)


def check_bucket_name(bucket_name):
    bucket_prefixes = [
        "gke-aieco-ray-",
        "gke-aieco-jupyter-",
        "gke-aieco-rag-",
    ]
    for bucket_prefix in bucket_prefixes:
        if bucket_name.startswith(bucket_prefix):
            return True
    return False

def delete_bucket(bucket_name):
    """Deletes a bucket. The bucket must be empty."""

    storage_client = storage.Client()

    bucket = storage_client.get_bucket(bucket_name)
    bucket.delete()

    print(f"Bucket {bucket.name} deleted")


def run(hours: int):
    """Deltes old CI buckets."""

    storage_client = storage.Client()
    buckets = storage_client.list_buckets()

    for bucket in buckets:
        if not check_old_create_time(bucket.time_created, hours):
            print(f"Skip bucket {bucket.name}, since it's age under {hours} hours.")
            continue
        if check_bucket_name(bucket.name):
            delete_bucket(bucket.name)
            print(f"Deleted bucket {bucket.name}")
        print(f"Skip bucket {bucket.name}")
