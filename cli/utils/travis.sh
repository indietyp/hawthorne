#!/bin/bash
version=$(git describe --abbrev=0 --tags --match="v*")
version=${version:1}

branch=$(git rev-parse --abbrev-ref HEAD)

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

if [ -z "$TRAVIS_TAG" ]; then
  docker tag indietyp/hawthorne:latest indietyp/hawthorne:experimental
  docker push indietyp/hawthorne:experimental
else
  docker tag indietyp/hawthorne:latest indietyp/hawthorne:$version
  docker push indietyp/hawthorne:$version

  if [[ branch = 'master' ]]; then
    docker tag indietyp/hawthorne:latest indietyp/hawthorne:stable
    docker push indietyp/hawthorne:stable
  fi

fi

docker push indietyp/hawthorne:latest

# TODO:
# push to API to deploy
# travis.indietyp.com/hawthorne -> deploy and run tests
# travis.hawthornepanel.org
