# BOSH Release for logsearch-for-cloudfoundry

## Usage

To use this bosh release, first upload it to your bosh:

```
bosh target BOSH_HOST
git clone https://github.com/cloudfoundry-community/logsearch-for-cloudfoundry-boshrelease.git
cd logsearch-for-cloudfoundry-boshrelease
bosh upload release releases/logsearch-for-cloudfoundry-1.yml
```

For [bosh-lite](https://github.com/cloudfoundry/bosh-lite), you can quickly create a deployment manifest & deploy a cluster:

```
templates/make_manifest warden
bosh -n deploy
```

For AWS EC2, create a single VM:

```
templates/make_manifest aws-ec2
bosh -n deploy
```

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
