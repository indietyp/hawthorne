#!/bin/bash
version=$(git describe --abbrev=0 --tags --match="v*")
version=${version:1}

branch=$(git rev-parse --abbrev-ref HEAD)

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

docker tag indietyp/hawthorne:latest indietyp/hawthorne:$version
docker push indietyp/hawthorne:latest

if [[ branch = 'master' ]]; then
  docker tag indietyp/hawthorne:latest indietyp/hawthorne:stable
  docker push indietyp/hawthorne:stable
fi

docker push indietyp/hawthorne:$version
