#!/bin/bash -e
basedir=$(cd `dirname $0`/..; pwd)

echo "====> Building"
$basedir/bin/build.sh
echo "====> Running tests"
$basedir/bin/run-tests.sh