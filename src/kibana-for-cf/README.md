# Packaging up Kibana with the cf_authentication plugin.

_NB:  Until Kibana actually supports an external plugin folder and a way to include some NPM dependancies, this process is rather hacky.  Hopefully we can improve that soon_

0.  Clone https://github.com/elastic/kibana
0.  Apply the `cf_authentication_plugin.patch` - `git apply ~/src/logsearch-for-cloudfoundry/logsearch-for-cloudfoundry-boshrelease/src/kibana-for-cf/cf_authentication_plugin.patch`
0.  Build Kibana - `grunt build`.  You want `target/kibana-4.2.0-snapshot-linux-x64.tar.gz`
0.  Commit your changes to kibana; capture a new patch with `git format-patch master --stdout > ~/src/logsearch-for-cloudfoundry/logsearch-for-cloudfoundry-boshrelease/src/kibana-for-cf/cf_authentication_plugin.patch`