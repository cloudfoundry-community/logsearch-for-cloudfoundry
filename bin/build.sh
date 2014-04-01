#!/bin/bash -e
# Defaults you can override with environment variables
echo "====> Building..."

LS_HEAP_SIZE="${LS_HEAP_SIZE:=500m}"

SCRIPT_DIR=$(cd `dirname $0`/..; pwd)

#Speedup jruby startup time - https://github.com/jruby/jruby/wiki/Improving-startup-time#wiki-tiered-compilation-64-bit
export JAVA_OPTS="$JAVA_OPTS -XX:+TieredCompilation -XX:TieredStopAtLevel=1"

pushd $SCRIPT_DIR/vendor/logstash > /dev/null
. bin/logstash.lib.sh
popd > /dev/null

setup

compile() {
  printf "Processing \n    $1\n >> $SCRIPT_DIR/target/logstash-filters-cf/logstash-filters-cf.conf\n"
  $RUBYCMD -e "require 'erb'; puts ERB.new(File.read('$1')).result(binding)" >> $SCRIPT_DIR/target/logstash-filters-cf/logstash-filters-cf.conf
}

mkdir -p $SCRIPT_DIR/target
rm -rf $SCRIPT_DIR/target/*
mkdir -p $SCRIPT_DIR/target/logstash-filters-cf

compile "$SCRIPT_DIR/src/filters-cf.conf.erb"

