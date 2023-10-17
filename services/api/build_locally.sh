#!/bin/sh
source ./.env
REPOSITORY=private-llm-fastapi-server
IMAGE_TAG=latest
docker build --build-arg="COMMITHASH=localtest" -t $REPOSITORY:$IMAGE_TAG .

docker run --rm -p 4001:4000 --env-file ./.env $REPOSITORY:$IMAGE_TAG