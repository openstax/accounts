#!/bin/bash

ENV_NAME=p-`cat accounts-git/.git/short_ref`
echo "ENV_NAME: $ENV_NAME"

export AWS_SECRET_ACCESS_KEY=$AWS_SECRET
export AWS_ACCESS_KEY_ID=$AWS_KEY

set -xe 

cd /accounts-deployment/scripts
./delete_env --region us-east-2 --env_name "$ENV_NAME" --do_it
