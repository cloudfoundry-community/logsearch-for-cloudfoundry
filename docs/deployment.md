[<-home page](../README.md)

### Deployment

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

#### UAA OAuth

Logsearch-for-CloudFoundry provides [kibana plugin](https://github.com/logsearch/logsearch-for-cloudfoundry/tree/develop/src/kibana-cf_authentication) to ask the user for credentials and perform an OAuth handshake with the CloudFoundry UAA server before serving requests.

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

</br>[<- prev page](jobs.md) | [next page ->](logs-parsing.md)
