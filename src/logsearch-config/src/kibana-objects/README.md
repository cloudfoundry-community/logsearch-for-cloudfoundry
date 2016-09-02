Import kibana objects:

```
cat kibana.json | curl --data-binary @- http://10.10.3.51:9200/_bulk
```
