## Logsearch for Cloud Foundry

A Logsearch addon that customises Logsearch to work with Cloud Foundry data

### Roadmap

* CF Operator dashboards - ingest, parse and analyse data from CF runtime components. [WIP]
* CF application dashboards - ingest, parse and analyse application logs and metrics form the Doppler Firehose [WIP]
* Multi-tenancy - Integration with CF UUA to only allow app users to see their own logs/metrics
* cf-cli plugin - A plugin for the cf-cli to enable searching of an applications logs - eg:

        cf log-search APP "type:RTR AND url:index.html"

* Per App/Space Kibana dashboards

### Getting Started

### Adding to an existing Cloud Foundry + Logsearch deployments

This has been tested on cf-release v205 and logsearch-boshrelease v19.

0.  Deploy the `ingestor_cloudfoundry` job to your existing logsearch deployment.

  * `bosh upload release https://logsearch-for-cloudfoundry-boshrelease.s3.amazonaws.com/boshrelease-logsearch-for-cloudfoundry-0%2Bdev.3.tgz`
  * Add and configure the `ingestor_cloudfoundry` job to your logsearch deploy manifest:
           releases:
  	          - name: logsearch-for-cloudfoundry
                version: latest    
  
           jobs:
             - name: ingestor_cloudfoundry
               release: logsearch-for-cloudfoundry
               templates: 
               - name: ingestor_cloudfoundry-firehose
               instances: 1
               resource_pool: small_z1
               networks: z1
               persistent_disk: 0
  
           properties:
               ingestor_cloudfoundry-firehose:
                 debug: true
                 uua-endpoint: "https://uaa.10.244.0.34.xip.io/oauth/authorize"
                 doppler-endpoint: "wss://doppler.10.244.0.34.xip.io"
                 skip-ssl-validation: true
                 firehose-user: admin
                 firehose-password: admin
                 syslog-server: "10.244.10.6:514"
  
   * Colocate the `cf_app_details_cache` template on all your log_parser jobs: 

           jobs:
             - name: log_parser
               templates: 
               - name: log_parser
               - { name: cf_app_details_cache, release: logsearch-for-cloudfoundry }
               ...snip...

   * Include `logsearch-for-cloudfoundry/logstash-filters-default.conf` log_parsing rules
           properties:
             logstash_parser:
           <% filtersconf = File.join(File.dirname(File.expand_path(__FILE__)), 'path/to/logsearch-for-  cloudfoundry/logstash-filters-default.conf') %>
                filters: |
                        <%= File.read(filtersconf).gsub(/^/, '            ').strip %>

   * `bosh deploy`
   * All app logs from your CF deployment should now be forwarded into your logsearch cluster.  Find them by searching for `@type:cloudfoundry_doppler`.  Make useful dashboards like the below:
   ![screen shot 2015-03-30 at 12 48 38](https://cloud.githubusercontent.com/assets/227505/6895741/236ac118-d6db-11e4-802d-19f548d323f5.png)

### Developing

0. INSIDE your Logsearch-workspace,

```
git clone git@github.com:logsearch/logsearch-for-cloudfoundry.git ~/src/logsearch-for-cloudfoundry
cd ~/src/logsearch-for-cloudfoundry
bin/install_dependancies
bin/test
```

0. Make a failing test under `test/`
0. Run the tests `bin/test`
0. Make tests pass by writing code under `src/`
0. Ensure tests are green.
0. Create PR!

