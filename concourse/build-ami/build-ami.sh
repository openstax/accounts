#!/bin/bash
SHA=`cat accounts-git/.git/short_ref`
echo "SHA: $SHA"

export AWS_SECRET_ACCESS_KEY=$AWS_SECRET
export AWS_ACCESS_KEY_ID=$AWS_KEY

set -xe 

./build_image --region us-east-2 --verbose --do_it --sha ${SHA} 2>&1 | tee /tmp/build.out

grep "amazon-ebs: AMI: ami-" /tmp/build.out | grep -v "ui" | awk '{print $4}' >> accounts-ami/ami

cat accounts-ami/ami
