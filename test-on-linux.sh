#!/bin/sh

set -eu

current_datetime=$(date +"%Y%m%d_%H%M%S")
local_name="scripting_core_$current_datetime"

# test on arm64 instead of amd64 to avoid issues with virtualisation + check API much faster
docker buildx build --platform linux/arm64 . -t "$local_name" -o "type=docker"
docker run --rm -it --platform linux/arm64 "$local_name"
docker image rm "$local_name" -f
