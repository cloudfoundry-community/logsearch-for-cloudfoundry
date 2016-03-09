# Logsearch for Cloud Foundry

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

### 3. Upload LogSearch-for-CloudFoundry release to your BOSH director

```sh
$ bosh create release
$ bosh upload release
```

### 2. Extend the LogSearch deployment manifest with LogSearch-for-CloudFoundry

#### Without Kibana UAA authentication

```sh
$ vim templates/logsearch-for-cf.example.yml
$ scripts/generate_deployment_manifest ~/workspace/logsearch.yml templates/logsearch-for-cf.example.yml > ~/workspace/logsearch-with-logsearch-for-cf.yml
```

#### With Kibana UAA authentication

```sh
$ vim templates/logsearch-for-cf.example-with-uaa-auth.yml
$ scripts/generate_deployment_manifest ~/workspace/logsearch.yml templates/t/logsearch-for-cf.example-with-uaa-auth.yml > ~/workspace/logsearch-with-logsearch-for-cf.yml
```

### 3. Update the logsearch deployment with the new manifest

```sh
$ bosh deployment ~/workspace/logsearch-with-logsearch-for-cf.yml
$ bosh deploy
```

#### If UAA authentication is enabled

```sh
$ bosh run errand create-uaa-client
```
