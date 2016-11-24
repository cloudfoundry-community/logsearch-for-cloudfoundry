[<-home page](../README.md)

### Troubleshooting

* Note that if you change ES mappings the changes are applied to new indicies only.

* Consider checking Logstash logs for errors and warnings: `/var/vcap/sys/log/parser/parser.stdout.log`

* Look into full Logstash conf to understand the full chain of parsing: `/var/vcap/jobs/parser/config/logstash.conf`

</br>[<- prev page](customization.md) | [next page ->](versions.md)
