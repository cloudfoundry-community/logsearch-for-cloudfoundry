#!/bin/bash -ex
# Defaults you can override with environment variables
echo "====> Building..."

LS_HEAP_SIZE="${LS_HEAP_SIZE:=500m}"

basedir=$(cd `dirname $0`/..; pwd)

#Speedup jruby startup time - https://github.com/jruby/jruby/wiki/Improving-startup-time#wiki-tiered-compilation-64-bit
export JAVA_OPTS="$JAVA_OPTS -XX:+TieredCompilation -XX:TieredStopAtLevel=1"

pushd $basedir/vendor/logstash 
. bin/logstash.lib.sh
popd 

setup

compile() {
  echo "Processing $1 >> target/logstash.filters.cloudfoundry.conf"
  $RUBYCMD -e "require 'erb'; puts ERB.new(File.read('$1')).result(binding)" >> target/logstash.filters.cloudfoundry.conf
}

mkdir -p target
rm -rf target/*

compile 'src/syslog_cf.conf.erb'

