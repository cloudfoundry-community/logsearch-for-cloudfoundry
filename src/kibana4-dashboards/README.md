Import kibana dashboards:

```
cat kibana.json | curl --data-binary=@- api.logsearch2.example.com:9200/_bulk
```