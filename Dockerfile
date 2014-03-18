FROM ubuntu:precise
RUN apt-get update && apt-get install openjdk-7-jre -y
ADD . /docker
RUN pushd vendor/logstash; make vendor-jruby; bin/logstash deps; popd
ENTRYPOINT /docker/bin/build.sh