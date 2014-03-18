#!/bin/bash -ex
echo "====> Running tests..."

#Speedup jruby startup time - https://github.com/jruby/jruby/wiki/Improving-startup-time#wiki-tiered-compilation-64-bit
export JAVA_OPTS="$JAVA_OPTS -XX:+TieredCompilation -XX:TieredStopAtLevel=1"

vendor/logstash/bin/logstash rspec spec/*_spec.rb