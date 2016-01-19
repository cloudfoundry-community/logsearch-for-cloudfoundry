#!/bin/bash -x

cd logsearch-for-cloudfoundry/src/logsearch-config

bin/install-dependencies

export SPEC_OPTS="--format documentation"
vendor/logstash/vendor/jruby/bin/jruby -S rake test
