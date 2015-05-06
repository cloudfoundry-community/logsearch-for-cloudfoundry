Import kibana dashboards:

```
curl https://github.com/logsearch/logsearch-for-cloudfoundry/blob/master/src/kibana4-dashboards/kibana.json | curl --data-binary @- api.logsearch2.example.com:9200/_bulk
```
