## Log parsing rules for Cloud Foundry

Log parsing rules for for cloudfoundry logs

### Getting Started

*On Mac OX Mavericks* 
Make sure you have [java](http://www.java.com/) installed, then clone this
repository and install the dependencies it needs (it'll take a few minutes).

    $ git clone git@github.com:cityindex/logstash-filters-internal.git
    $ cd logstash-filters-internal
    $ ./bin/install_deps.sh

When you ready to test the changes you've made to filters run the helper
scripts.

    $ ./bin/build.sh && ./bin/test.sh
    compiling src/100-cloudfoundry.conf.erb...done
    ..

    Finished in 0.385 seconds
    2 examples, 0 failures
