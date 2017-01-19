[<-home page](../README.md)

### Deployment

This documentation assumes that you have a working LogSearch deployment and that bosh_cli is pointed at the right director.

### 1. Fetch your running LogSearch BOSH deployment manifest

```sh
$ bosh download manifest $logsearch_deployment_name > ~/workspace/logsearch.yml
```

### 2. Download the latest LogSearch-for-CloudFoundry release

> NOTE: At the moment you can get working LogSearch-for-CloudFoundry release by cloning Git repository and creating bosh release from it.
> 
> Example:

> ```sh
> $ git pull https://github.com/cloudfoundry-community/logsearch-for-cloudfoundry.git
> $ cd logsearch-for-cloudfoundry
> $ git submodule update --init --recursive
> $ bosh create release
> ```

### 3. Upload LogSearch-for-CloudFoundry release to your BOSH director

```sh
$ bosh upload release
```

### 4. Extend the LogSearch deployment manifest with LogSearch-for-CloudFoundry

#### 4-a) Standalone Kibana with UAA OAuth enabled

Logsearch-for-CloudFoundry provides [kibana plugin](https://github.com/logsearch/logsearch-for-cloudfoundry/tree/develop/src/kibana-cf_authentication) to ask the user for credentials and perform an OAuth handshake with the CloudFoundry UAA server before serving requests. The plugin can be added to the standalone Kibana deployed as part of the Logsearch release. If you are choosing to proceed with a standalone Kibana and enable the authentication in it, then use `templates/stub.logsearch-for-cf.standalone-kibana-with-auth.yml` stub and customise it with your deploy settings:

```sh
$ vim templates/stub.logsearch-for-cf.standalone-kibana-with-auth.yml
$ scripts/generate_deployment_manifest ~/workspace/logsearch.yml templates/stub.logsearch-for-cf.standalone-kibana-with-auth.yml > ~/workspace/logsearch-with-logsearch-for-cf.yml
```

#### 4-b) Kibana deployed as CF application with UAA OAuth enabled

There is a possibility to deploy [Kibana as a CloudFoundry application](features.md#possibility-to-deploy-kibana-as-cloudfoundry-application). Deployed Kibana will already include the authentication plugin providing UAA OAuth. To enable this feature use `templates/stub.logsearch-for-cf.cf-kibana.yml` stub and customise it with your deploy settings.

> NOTE: If you choose to deploy Kibana as a CF application, then, most probably, you don't need to have a standalone Kibana instance anymore (one deployed in Logsearch release). You can disable it in `~/workspace/logsearch.yml`:
> ```yml
> jobs:
> ...
> - instances: 0
>   name: kibana
>   ...
> ```

```sh
$ vim templates/stub.logsearch-for-cf.cf-kibana.yml
$ scripts/generate_deployment_manifest ~/workspace/logsearch.yml templates/stub.logsearch-for-cf.cf-kibana.yml > ~/workspace/logsearch-with-logsearch-for-cf.yml
```

### 5. Update the logsearch deployment with the new manifest

```sh
$ bosh deployment ~/workspace/logsearch-with-logsearch-for-cf.yml
$ bosh deploy
```

#### 5-b) If deploy Kibana as CF application with UAA OAuth enabled

If you choose to deploy Kibana as a CF app, then you should additionally run `cf-kibana` errand task after the deploy:

```sh
$ bosh run errand cf-kibana
```
> NOTE: Before running the job, make sure to create a security group in your CF which you pass as `cf-kibana.cloudfoundry.api_security_group`:
>
> ```json
>  [
>   {
>    "protocol": "tcp",
>    "destination": "MY_CF_API_IP",
>    "ports": "80-443",
>    "log": true 
>   }
>  ]
> ```

### 6. Upload Kibana saved objects

To upload Kibana [saved objects](features.md#kibana-saved-objects), run `upload-kibana-objects` errand task after deploy:

```sh
$ bosh run errand upload-kibana-objects
```

### 7. Run smoke-tests to verify your deployment

```sh
$ bosh run errand smoke-tests
```

### 8. Update CloudFoundry deployment to forward component logs to ingestor

```yaml
properties:
  syslog_daemon_config:
    address: ls-router-static-ip
    port: 5514
```

### 9. Update CloudFoundry deployment to include ELK URI to the whitelist of UAA logout redirects

If you've chosen to enable UAA Authentication in Kibana, then make sure to include your ELK URI(s) to the whitelist of URIs that UAA uses to redirect after logout. Update `login.logout.*` properites in your CF deployment like the following:

```
properties:
...
login:
  logout:
    redirect:
      url: /login
      parameter:
        disable: false
        whitelist:
        - https://my_kibana_domain/login
        - http://my_kibana_domain/login
...
```
> NOTE: If you skip this step, the UAA authentication will still be working in Kibana, but your ability to get automatically redirected to the Kibana home page after logout will be lost. Read more about [the redirect feature](features.md#redirect-after-logout) if necessary.

</br>[<- prev page](jobs.md) | [next page ->](logs-parsing.md)
