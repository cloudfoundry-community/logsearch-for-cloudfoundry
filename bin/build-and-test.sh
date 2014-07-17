#!/bin/bash

set -e

echo "===> Building ..."

mkdir -p target/logstash
./vendor/logsearch-filters-common/bin/build.sh src/logstash/cloudfoundry.conf.erb > target/logstash/cloudfoundry.conf


echo "===> Testing ..."

./vendor/logsearch-filters-common/bin/test.sh
