# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Build stage: install dependencies using full Python image
FROM python:3.11-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --target=/packages -r requirements.txt

# Final stage: minimal distroless image (runs as nonroot uid 65532 by default)
FROM gcr.io/distroless/python3-debian12:nonroot

COPY --from=builder /packages /packages
COPY --chown=nonroot:nonroot . /workspace/frontend

WORKDIR /workspace/frontend

ENV PYTHONPATH=/packages
ENV HF_HOME=/tmp/hf-cache
# The root filesystem is read-only, so __pycache__ writes next to modules would fail on every
# import. Skip them explicitly rather than retrying and failing.
ENV PYTHONDONTWRITEBYTECODE=1

CMD ["main.py"]
