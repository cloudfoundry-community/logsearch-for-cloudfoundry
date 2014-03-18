log_parsers-cloudfoundry
========================

Log parsing rules for for cloudfoundry logs

### Running the tests

*On Mac OX Mavericks* 

* Skip the steps for the dependancies you already have - eg, Java etc.  This guide assumes your starting with a fresh Mavericks install (ie, with just the system Ruby 2.0.0 installed)

```
#Install Java - tested with
# $ java -version
# java version "1.7.0_51"
# Java(TM) SE Runtime Environment (build 1.7.0_51-b13)
# Java HotSpot(TM) 64-Bit Server VM (build 24.51-b03, mixed mode)

# Grab & init this repository
git clone https://github.com/logsearch/log_parsers-cloudfoundry.git
cd log_parsers-cloudfoundry
git submodule update --init --recursive

# Install logstash ruby dependencies
pushd vendor/logstash 
make vendor-jruby
bin/logstash deps
popd

# Run the tests
bin/run-tests.sh

# $ bin/run-tests.sh 
# ....
# 
# Finished in 0.145 seconds
# 4 examples, 0 failures
# 
# real	0m4.014s
# user	0m5.251s
# sys	0m0.277s

```