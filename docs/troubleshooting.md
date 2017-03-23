[<-home page](../README.md)

### Troubleshooting

Find some useful tips:

* Note that if you change ES mappings the changes are applied to new indicies only.

* Consider checking Logstash logs for errors and warnings: `/var/vcap/sys/log/parser/parser.stdout.log`

* Look into full Logstash conf to understand the full chain of parsing: `/var/vcap/jobs/parser/config/logstash.conf`

#### Common Issues
Here you can find links to common issues that you might meet and how to solve them:

1. [Kibana authentication fails with 500](https://github.com/cloudfoundry-community/logsearch-for-cloudfoundry/issues/203)

2. [Platform logs don't show up in Kibana](https://github.com/cloudfoundry-community/logsearch-for-cloudfoundry/issues/237)

</br>[<- prev page](customization.md) | [next page ->](versions.md)
