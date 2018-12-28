#!/bin/bash
version=$(git describe --abbrev=0 --tags --match="v*")
branch=$(git rev-parse --abbrev-ref HEAD)

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
docker push indietyp/hawthorne:latest

if [[ branch = 'master' ]]; then
  docker push indietyp/hawthorne:$stable
fi
docker push indietyp/hawthorne:$version
