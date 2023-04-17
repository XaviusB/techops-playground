#!/usr/bin/env bash

function create_minio_bucket () {
  local bucket_name
  local "{@}"
  bucket_name=${bucket_name:? need a bucke name}

     kubectl run --namespace minio minio-client \
     --rm --tty -i --restart='Never' \
     --env MINIO_SERVER_ROOT_USER="${MINIO_USERNAME}" \
     --env MINIO_SERVER_ROOT_PASSWORD="${MINIO_USERNAME}" \
     --env MINIO_SERVER_HOST=minio.minio.svc.cluster.local \
     --image docker.io/bitnami/minio-client:2023.4.12-debian-11-r1 -- admin info minio
}

export -f create_minio_bucket
