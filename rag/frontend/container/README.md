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
frontend_image = "<REGION>-docker.pkg.dev/<PROJECT_ID>/<REPO>/rag-frontend:latest"
# Or with digest for pinned supply-chain compliance:
# frontend_image = "<REGION>-docker.pkg.dev/<PROJECT_ID>/<REPO>/rag-frontend@sha256:<digest>"
```

To get the digest after pushing:

```bash
docker inspect --format='{{index .RepoDigests 0}}' \
  <REGION>-docker.pkg.dev/<PROJECT_ID>/<REPO>/rag-frontend:latest
```
