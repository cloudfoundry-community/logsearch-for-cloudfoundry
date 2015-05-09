Import kibana dashboards:

```
curl https://raw.githubusercontent.com/logsearch/logsearch-for-cloudfoundry/master/src/kibana4-dashboards/kibana.json | curl --data-binary @- http://10.10.3.51:9200/_bulk
```
