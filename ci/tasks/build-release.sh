#!/bin/bash -ex

version="$(cat logsearch-for-cloudfoundry-version/number)"

cd logsearch-for-cloudfoundry/src/logsearch-config
rake build

cd ../..
bosh create release --force --with-tarball --name logsearch-for-cloudfoundry --version "$version"
