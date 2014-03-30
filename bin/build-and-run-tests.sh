#!/bin/bash -e
basedir=$(cd `dirname $0`/..; pwd)
$basedir/bin/build.sh 
$basedir/bin/run-tests.sh 
