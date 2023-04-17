#!/bin/bash

set -euo pipefail
set -x
GITEA_USERNAME=root
PASSWORD=Kwcpa32Kwcpa32
org_name=myOrg2

MINIO_PASSWORD=adminadmin
MINIO_USERNAME=adminadmin

source lib/minio.sh

mc alias set myServer http://api.minio.localhost:80 "${MINIO_USERNAME}" "${MINIO_PASSWORD}" --api S3v4
bucket=$(mc ls myServer/ --json | jq 'select (.key == "test/")')
if [ -z "${bucket}" ]; then
  mc mb myServer/test
fi

cat <<EOF > /tmp/gitea-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::test"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads"
      ],
      "Resource": [
        "arn:aws:s3:::test"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:ListMultipartUploadParts",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::test/*"
      ]
    }
  ]
}
EOF

user=$(mc admin user list myServer --json | jq 'select (.accessKey == "${GITEA_USERNAME}")')
if [ -z "${user}" ]; then
  mc admin user add myServer "${GITEA_USERNAME}" "${PASSWORD}"
fi
policy=$(mc admin policy list "${GITEA_USERNAME}" --json | jq 'select (.name == "'"${GITEA_USERNAME}"'" )')
if [ -z "${policy}" ]; then
  mc admin policy create myServer gitea-policy /tmp/gitea-policy.json
fi
mc admin policy set myServer gitea-policy user="${GITEA_USERNAME}"
mc admin user info myServer "${GITEA_USERNAME}" --json | jq -r '.policy[].name'
