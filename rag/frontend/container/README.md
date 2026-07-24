# Frontend Container

This directory contains the source code and Dockerfile for the RAG frontend Flask web server.

Before running `terraform apply`, you must push this image to your own Artifact Registry repository and set the `frontend_image` variable in `workloads.tfvars`.

## Prerequisites

- An Artifact Registry Docker repository in your GCP project.
- Authenticated Docker client (`gcloud auth configure-docker <REGION>-docker.pkg.dev`).

## Option A — Local Docker build

```bash
cd rag/frontend/container
docker build --platform linux/amd64 -t rag-frontend:latest .
```

To push to Artifact Registry for GKE deployment:

```bash
docker tag rag-frontend:latest <REGION>-docker.pkg.dev/<PROJECT_ID>/<REPO>/rag-frontend:latest
docker push <REGION>-docker.pkg.dev/<PROJECT_ID>/<REPO>/rag-frontend:latest
```

## Option B — Cloud Build

Builds and pushes to Artifact Registry in one step:

```bash
cd rag/frontend/container
gcloud builds submit \
  --tag <REGION>-docker.pkg.dev/<PROJECT_ID>/<REPO>/rag-frontend:latest .
```

## Set the image reference

After pushing, update `workloads.tfvars`:

```hcl
# Pin by digest so the deployed image cannot change underneath you:
frontend_image = "<REGION>-docker.pkg.dev/<PROJECT_ID>/<REPO>/rag-frontend@sha256:<DIGEST>"
# A mutable tag also works for quick local testing, but is not recommended outside of it:
# frontend_image = "<REGION>-docker.pkg.dev/<PROJECT_ID>/<REPO>/rag-frontend:latest"
```

To get the digest after pushing:

```bash
docker inspect --format='{{index .RepoDigests 0}}' \
  <REGION>-docker.pkg.dev/<PROJECT_ID>/<REPO>/rag-frontend:latest
```

## Notes

- **Embedding model cache.** The container runs with a read-only root filesystem and writes the
  Hugging Face cache to `/tmp/hf-cache`, backed by an `emptyDir`. That cache does not survive a pod
  restart, and each replica downloads its own copy of the embedding model
  (`intfloat/multilingual-e5-small`, ~500Mi) on first request. This keeps the quick-start simple; for
  a longer-lived or larger-scale deployment, back the cache with a `PersistentVolumeClaim` or bake
  the model into the image instead.
- **Registry.** The commands above use Artifact Registry (`<REGION>-docker.pkg.dev`), which is what
  you should use for your own deployments. The CI pipeline in `cloudbuild.yaml` pushes to
  `gcr.io/$PROJECT_ID/rag-frontend` instead — that is a throwaway image built per-run for testing
  only, and is not the recommended path for users.
