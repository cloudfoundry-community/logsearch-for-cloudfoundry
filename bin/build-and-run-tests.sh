#!/bin/bash -ex
basedir=$(cd `dirname $0`/..; pwd)
echo "build + test"
$basedir/bin/build.sh 
$basedir/bin/run-tests.sh 
