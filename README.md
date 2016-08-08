# Logsearch for Cloud Foundry

### Build status

[![Build Status](https://travis-ci.org/cloudfoundry-community/logsearch-for-cloudfoundry.svg?branch=master)](https://travis-ci.org/cloudfoundry-community/logsearch-for-cloudfoundry)

LogStash parsing rules for some CloudFoundry-specific log formats:

* App logs
* Container metrics
* UAA logs

## Deploying

This documentation assumes that you have a working LogSearch deployment and that bosh_cli is pointed at the right director.

### 1. Fetch your running LogSearch BOSH deployment manifest

```sh
$ bosh download manifest $logsearch_deployment_name > ~/workspace/logsearch.yml
```

### 2. Upload LogSearch-for-CloudFoundry release to your BOSH director

```sh
$ bosh create release
$ bosh upload release
```

### 3. Extend the LogSearch deployment manifest with LogSearch-for-CloudFoundry

At this point there is a choice to make. If Kibana is publicly exposed in your deployment and you wish to protect it with authentication, you have 2 options.

#### Basic auth

You can configure the haproxy job in logsearch-boshrelease to act as an authentication proxy in front of Kibana. Configuration for the haproxy job looks like this:

```yaml
properties:
  haproxy:
    kibana:
      auth:
        user: user
        password: password
```

then:

```sh
$ vim templates/logsearch-for-cf.example.yml
$ scripts/generate_deployment_manifest ~/workspace/logsearch.yml templates/logsearch-for-cf.example.yml > ~/workspace/logsearch-with-logsearch-for-cf.yml
```

#### UAA OAuth

Alternatively, you can use the [kibana plugin](https://github.com/logsearch/logsearch-for-cloudfoundry/tree/master/src/kibana-cf_authentication) provided by this release to get kibana to ask the user for credentials and perform an OAuth handshake with the CloudFoundry UAA server before serving requests.

```sh
$ vim templates/logsearch-for-cf.example-with-uaa-auth.yml
$ scripts/generate_deployment_manifest ~/workspace/logsearch.yml templates/logsearch-for-cf.example-with-uaa-auth.yml > ~/workspace/logsearch-with-logsearch-for-cf.yml
```

### 4. Update the logsearch deployment with the new manifest

```sh
$ bosh deployment ~/workspace/logsearch-with-logsearch-for-cf.yml
$ bosh deploy
```

### 5. Update Cloud Foundry deployment to forward component logs to ingestor

```yaml
properties:
  syslog_daemon_config:
    address: haproxy-static-ip
    port: 5514
```

#### If UAA authentication is enabled

```sh
$ bosh run errand create-uaa-client
```

#### Collecting application events

Note: To collect Cloud Foundry application events, configure and deploy [cf-app-events-logger](https://github.com/18F/cf-app-events-logger) to your Cloud Foundry instance; application events will be printed to standard output and collected via the firehose.
