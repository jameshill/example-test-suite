#!/bin/bash

set -e

DOCKERFILE=${DOCKERFILE:-Dockerfile}
IMAGE="${DOCKER_IMAGE}:${BUILDKITE_COMMIT}"

echo "+++ Building Docker image"
docker build -f "$DOCKERFILE" -t "$IMAGE" .

echo "+++ Pushing Docker image"
docker push "$IMAGE"
