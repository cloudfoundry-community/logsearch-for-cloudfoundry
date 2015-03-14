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

* INSIDE your Logsearch-workspace,

```
git clone git@github.com:logsearch/logsearch-for-cloudfoundry.git ~/src/logsearch-for-cloudfoundry
cd ~/src/logsearch-for-cloudfoundry
bin/install_dependancies
bin/build
```

### Developing

0. Make a failing test under `test/`
0. Run the tests `bin/test`
0. Make tests pass by writing code under `src/`
0. Ensure tests are green.
0. Create PR!

