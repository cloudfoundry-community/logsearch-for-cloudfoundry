#Speedup jruby startup time - https://github.com/jruby/jruby/wiki/Improving-startup-time#wiki-tiered-compilation-64-bit
export JAVA_OPTS="$JAVA_OPTS -XX:+TieredCompilation -XX:TieredStopAtLevel=1"

time vendor/logstash/bin/logstash rspec spec/*_spec.rb