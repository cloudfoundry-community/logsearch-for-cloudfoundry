FROM ubuntu:precise
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install openjdk-7-jre-headless curl

ADD . /docker
RUN pushd vendor/logstash; make vendor-jruby; bin/logstash deps; popd
ENTRYPOINT /docker/bin/build.sh