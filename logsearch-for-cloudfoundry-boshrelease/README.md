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
