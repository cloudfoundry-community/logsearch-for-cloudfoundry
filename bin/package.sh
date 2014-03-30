#!/bin/bash -e
echo "====> Packaging..."

basedir=$(cd `dirname $0`/..; pwd)
BUILD_NUMBER=${BUILD_NUMBER:-dev}

pushd $basedir/target > /dev/null
tar cvzf logstash-filters-cf-${BUILD_NUMBER}.tgz logstash-filters-cf
popd > /dev/null