FROM buildpack-deps:xenial-scm

RUN set -x && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
  curl jq wget git build-essential

RUN \
  wget https://github.com/postmodern/ruby-install/archive/v0.6.0.tar.gz -P /tmp && \
  tar zxf /tmp/v0.6.0.tar.gz -C /tmp && \
  cd /tmp/ruby-install-0.6.0 && make install && \
  ruby-install ruby 2.3.1 && \
  rm -rf /usr/local/src/ruby-2.3.1 && \
  rm -rf /tmp/*

ENV PATH /opt/rubies/ruby-2.3.1/bin:$PATH

RUN \
  gem update --system && \
  gem install bundler --no-rdoc --no-ri && \
  gem install bosh_cli --no-rdoc --no-ri

RUN \
  curl -v -L -o /usr/bin/spiff https://github.com/cloudfoundry-incubator/spiff/releases/download/v1.0.7/spiff_linux_amd64 && \
  chmod +x /usr/bin/spiff

RUN \
  curl -v -L -o /usr/bin/spruce https://github.com/geofffranks/spruce/releases/download/v1.7.0/spruce-linux-amd64 && \
  chmod +x /usr/bin/spruce

RUN \
  curl -v -L -o /bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.1.3/dumb-init_1.1.3_amd64 && \
  chmod +x /bin/dumb-init

RUN \
  curl -v -L -o ./cf.tgz https://s3.amazonaws.com/go-cli/releases/v6.21.1/cf-cli_6.21.1_linux_x86-64.tgz && \
  tar xzvf ./cf.tgz -C /usr/bin/ && \
  chmod +x /usr/bin/cf && \
  rm -f ./cf.tgz

CMD ["irb"]
