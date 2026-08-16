#!/bin/bash

. ./build/docker/buildWithDocker.sh

docker buildx build -t okstarorg/ok-openfire:4.9.2 . --load
