#!/usr/bin/env sh

docker build -t terraform-bundle .
id=$(docker create terraform-bundle)
docker cp $id:/go/terraform-bundle.zip .
docker rm -v $id
