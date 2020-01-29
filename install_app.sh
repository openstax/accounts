#!/bin/bash

# Exit with non-zero status if a simple command fails, even with piping
# https://stackoverflow.com/a/4346420/1664216

set -e
set -o pipefail

# Script to run on the deployed server when the code has been
# updated (or on first deployment)

ruby_version=`cat .ruby-version`
echo Installing Ruby $ruby_version
source /home/ubuntu/rbenv-init && rbenv install -s $ruby_version

echo Installing bundler
# Get specific version of bundler used in the Gemfile.lock
BUNDLER_VERSION=`grep -A 2 "BUNDLED WITH" Gemfile.lock | tail -1`
gem install --conservative bundler -v $BUNDLER_VERSION

echo Installing gems
# After install do an rbenv rehash to make sure newly installed executables
# have shims available
bundle install --without development test
rbenv rehash

echo Done!
