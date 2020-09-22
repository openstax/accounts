#!/bin/bash

AMI=`cat -v accounts-ami/ami | sed 's/\^\[\[0m//g'`
cat -v accounts-ami/ami
echo "AMI: $AMI"

ENV_NAME=p-`cat accounts-git/.git/short_ref`
echo "ENV_NAME: $ENV_NAME"

export AWS_SECRET_ACCESS_KEY=$AWS_SECRET
export AWS_ACCESS_KEY_ID=$AWS_KEY

set -xe 

cd /accounts-deployment/scripts
./create_env --region us-east-2 --env_type prod_lite --do_it --social_secrets_type garbage --rds_snapshot accounts-autoqa-snapshot --env_name "$ENV_NAME" --image_id "$AMI"
