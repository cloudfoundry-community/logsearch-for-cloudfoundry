# Logsearch for Cloud Foundry

A Logsearch addon that customises Logsearch to work with Cloud Foundry data

It consumes the syslog component log streams AND the doppler firehose stream, to provide log dashboards for 2 distinct user groups:

* **cf-users** (those deploying apps to the CF cluster) see a tenanted view of the doppler firehose data stored in Logsearch for just the apps in spaces they are members of.  They access the data via an app deployed on CF, and are required to authenticated against the CF's UAA component using the same credentials they would use to interact via the `cf` CLI tool.
The video below shows this in action:

[![Logsearch for Cloudfoundry - CF User view](https://cloud.githubusercontent.com/assets/227505/7177797/848e43a4-e421-11e4-912a-8803c1864cc1.png)](https://youtu.be/M-ODQwm98YM)

* **cf-operators** (those responsible for operating the CF cluster) can see data for all cf-user apps as well as data from all underlying CF components and the NATs message bus.
The video below shows this in action:

[![Logsearch for Cloudfoundry - CF Operator view](https://cloud.githubusercontent.com/assets/227505/7177840/d32fa890-e421-11e4-9127-dd2ce2ef36b9.png)](https://youtu.be/gWfoHCQUixM)

To install, please use the logsearch-for-cloudfoundry-boshrelease, documented [here]( https://github.com/logsearch/logsearch-for-cloudfoundry/blob/master/logsearch-for-cloudfoundry-boshrelease/README.md )

## Roadmap

* cf-cli plugin - A plugin for the cf-cli to enable searching of an applications logs - eg:

        cf log-search APP "type:RTR AND url:index.html"

__Notes:__
  * All app logs from your CF deployment should now be forwarded into your logsearch cluster. 


# BOSH Release for logsearch-for-cloudfoundry

## Deploying logsearch-for-cloudfoundry

For [bosh-lite](https://github.com/cloudfoundry/bosh-lite):

0. Get source code

  ```
    git clone http://github.com/logsearch/logsearch-for-cloudfoundry
    cd logsearch-for-cloudfoundry/logsearch-for-cloudfoundry-boshrelease
  ```

0. Generate stub from one of the provided examples:

  ```
    cp templates/stub.warden.example.yml templates/stub.yml
    vim templates/stub.yml # Add customizations
  ```

0. Target bosh director

  ```
    bosh target 192.168.50.4 lite
  ```

0. Make manifest

  ```
    ./templates/make-manifest warden templates/stub.yml
  ```

0. Upload logsearch bosh release

  ```
    bosh upload release releases/logseach-for-cloudfoundry/logseach-for-cloudfoundry-5.yml
  ```

0. Perform deployment

  ```
    bosh  -n deploy
  ```

0. Run push-kibana bosh errand

  ```
    bosh run errand push-kibana # will deploy Kibana4 and some sample dashboards to your CF cluster
  ```

## Redeploying logsearch

Losearch-for-cloudfoundry requires some of the logsearch#log_parser job capabilities.
It extends the log parsing filters to allow logstash to properly parse the format of cloud foundry log output.

To do this, include the following in your `logstash#stub.yml` before generating your manifest:

```
...

properties:
 logstash_parser:
    filters: |
            <%= File.read("#{ENV['HOME']}/workspace/logsearch-for-cloudfoundry/target/logstash-filters-default.conf").gsub(/^/, '            ').strip %>

...
```

Now proceed by generating your manifest again and redeploying your logsearch deployment.


### Override security groups

For AWS & Openstack, the default deployment assumes there is a `default` security group. If you wish to use a different security group(s) then you can pass in additional configuration when running `make_manifest` above.

Create a file `my-networking.yml`:

``` yaml
---
networks:
  - name: logsearch-for-cloudfoundry1
    type: dynamic
    cloud_properties:
      security_groups:
        - logsearch-for-cloudfoundry
```

Where `- logsearch-for-cloudfoundry` means you wish to use an existing security group called `logsearch-for-cloudfoundry`.

You now suffix this file path to the `make_manifest` command:

```
templates/make_manifest openstack-nova my-networking.yml
bosh -n deploy
```