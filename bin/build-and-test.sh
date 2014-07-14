#!/bin/bash

set -e

echo "===> Building ..."

mkdir -p target
./vendor/logsearch-filters-common/bin/build.sh src/cloudfoundry.conf.erb > target/cloudfoundry.conf


echo "===> Testing ..."

./vendor/logsearch-filters-common/bin/test.sh
