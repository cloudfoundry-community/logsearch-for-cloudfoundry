FROM ubuntu:precise
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install openjdk-7-jre-headless curl build-essential git

ADD . /docker
WORKDIR /docker

RUN cd vendor/logstash; make vendor-jruby; bin/logstash deps