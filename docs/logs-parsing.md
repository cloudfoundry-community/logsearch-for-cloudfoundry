[<-home page](../README.md)
### Logs parsing

On this page you can read about parsing rules (Logstash filters) that Logsearch-for-cloudfoundry adds to _Logsearch_ parsing.

#### Indices

By default, Logsearch-for-cloudfoundry stores parsed logs in indices named `logs-%{[@metadata][index]}-%{+YYYY.MM.dd}`. And `%{[@metadata][index]}` is calculated as the following: 
* `platform` for CloudFoundry components logs, 
* `app-%{[cf][org]}-%{[cf][space]}` for application logs (including CloudFoundry logs about applications).

So **the following indices are created** as the result:
</br>`logs-platform-%{+YYYY.MM.dd}` for platform logs,
</br>`logs-app-%{[cf][org]}-%{[cf][space]}-%{+YYYY.MM.dd}` for application logs.

Please note that index name is [configurable](../templates/stub.logsearch-for-cloudfoundry.yml#L81) and can be customized. But it is highly recommended to **keep the name prefix `logs-*`**, because Elasticsearch [mappings](features.md#elasticsearch-mappings) uploaded during deploy rely on this prefix ([see](../src/logsearch-config/src/es-mappings/logs-template.json.erb#L2) `template` definition in mapping sources).

Also it can be useful to read how to [_get list of all indices in Elasticsearch_](https://www.elastic.co/guide/en/elasticsearch/reference/current/_list_all_indices.html).

#### Fields

Logserach-for-cloudfoundry provides Logstash parsing rules which used to parse incoming log event and create a set of fields from parsed data. Some fields are common for application and platform logs, some are event-specific. There are also system fields added by Logstash. Read below sections to get detailed information about fields the logs are split to when using Logsearch-for-cloudfoundry.

##### Common fields

These fields are common for application and platform logs and store the following information from log event:

* Log input (`@input`, `@index_type`)
* Log shipping (`@shipper.*` fields)
* Log source (`@source.*` fields)
* Log destination in Elasticsearch (`@metadata.index`, `@type`)
* Log message payload (`@message`, `@level`)
</br></br>

| Field | Value examples | Comment |
|-------|--------|---------|
| `@input` | syslog, relp, ... ||
| `@index_type` | app, platform | Either  _app_ or _platform_.</br>Default is _platform_.|
| `@metadata.index` | platform, app-myorg-myspace, ... | Constructed as _app-${org}-${space}_ for application logs. Note that _${space}_ and _${org}_ are ommitted in index name if corresponding info is missing in log event.</br></br>The field is used to set index name (`logstash_parser.elasticsearch.index` property in [config](../templates/stub.logsearch-for-cloudfoundry.yml#L81)).|
| `@shipper.priority` | 6, 14, ...||
| `@shipper.name` | doppler_syslog, vcap.nats_relp, ... ||
| `@source. host` | 192.168.111.63, ... ||
| `@source.deployment` | cf-full-diego, ... | For application logs this value is shipped within a log event.</br>For platform logs we provide a deployment [dictionary](../jobs/parser-config-lfc/templates/deployment_lookup.yml.erb) which uses deployment names set with `logstash_parser.deployment_name` [property](../templates/stub.logsearch-for-cloudfoundry.yml#L84) and maps CloudFoundry jobs to these names.</br>(NOTE: The deployment dictionary is applied in _Logsearch_ parsing rules) |
| `@source.job` | cell_z1, ... ||
| `@source.job_index` | 52ba268e-5578-4e79-afa2-2ddefd70badg, ... | Bosh ID of the job (guid) - value of `spec.id` extracted from Bosh for the job |
| `@source.index` | 0, 1, ... | Bosh instance index - value of `spec.index` extracted from Bosh for the job |
| `@source.vm` | cell_z1/0 | For those entries where `@source.index` is passed, calculated as `@source.job`/`@source.index` |
| `@source.component` | rep, nats, bbs, uaa, ... ||
| `@source.type` | APP, RTR, STG, ...</br>system, cf | For application logs the field is set with [_CloudFoundry log source types_](https://docs.cloudfoundry.org/devguide/deploy-apps/streaming-logs.html#format). Additionally, for log events that don't specify a source type we [use](../src/logsearch-config/src/logstash-filters/snippets/app.conf#L101)) a dictionary based on an event type:</br>`LogMessage -> LOG`,</br>`Error -> ERR`,</br>`ContainerMetric -> CONTAINER`,</br>`ValueMetric -> METRIC`,</br>`CounterEvent -> COUNT`,</br>`HttpStartStop -> HTTP`</br></br>For platform logs the value is either `system` or `cf`. |
| `@type` | LogMessage, Error, ValueMetric, ...</br>system, cf, haproxy, uaa, vcap |The field is used to define documents type in Elasticsearch (set in `logstash_parser.elasticsearch_index_type` [property](../templates/stub.logsearch-for-cloudfoundry.yml#L82)).</br>This field is set with values distinguishing logs of differnt types. |
| `@message` | This is a sample log message text ||
| `@level` | INFO, ERROR, WARN, ... ||
| `@raw` | \<13\>2016-09-26T18:20:25.134194+00:00 192.168.111.63 vcap.rep [job=cell_z1 index=0] My log message | This field stores an unparsed log event (as it came).</br></br>(NOTE: This field is provided by _Logsearch_ deployment) |
| `@timestamp` | September 26th 2016, 21:04:17.928 | The field is set with value of a log event timestamp (time when the log was collected by CloudFoundry logging agent). |
| `tags` | syslog_standard, app, logmessage, logmessage-app, ... | This field stores tags set during parsing. A specific tag is set in each parsing snippet which helps to track parsing (name of tag = name of snippet). Fail tags are set in case of parsing failures. |


##### Application CF meta fields

These fields are specific to _application_ logs only. They store CloudFoundry metadata about an application that emmitted the log or relates to the log event (e.g. metrics).

| Field | Values |
|-------|--------|
| `@cf.org_id` | 2d5f8dc7-dcf4-443b-9491-a54d27db785f, ... |
| `@cf.org` | myorg, ... |
| `@cf.space_id` | c9290e71-780b-43ee-8074-f37ee33b2ff7, ... |
| `@cf.space` | myspace, ... |
| `@cf.app_id` | ee61d1b6-f08f-4f93-b93f-2a9b0ae82dfc, ... |
| `@cf.app` | myapp, ... |
| `@cf.app_instance` | 0, 1, 2, ... |

##### Event specific fields

* _Application logs_ are shipped in JSON events. Set of JSON fields varies for different event types. All common fields from JSON are mapped accordingly to common fields and CF meta fields listed above. Other JSON fields (those extra fields specific to a particular event type) are stored as `<@type>.<json field name>`.</br>Example: `logmessage.message_type`.</br></br>Additionally, format of a log line (message shipped in a log event) may vary for differnt events. Parsed fields from a log line are stored as `<@source.type>.<field name>`. Example: `rtr.path`.

* _Platform logs_ are shipped in events of plain text format. The format is parsed and common fields are set from the parsed data.</br></br>A format of a log line (message shipped in a log event) may vary for differnt event types. For consistency we store fields parsed from the log line as `<@source.component>.<field name>`. Example: `uaa.pid`.

##### Elasticsearch meta fields

Each parsed log event has also a set of [_Elasticsearch meta fields_](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-fields.html) (prefixed with _ underscore).


#### Parsing rules

Parsing rules are split to several logical [snippets](../src/logsearch-config/src/logstash-filters/snippets) for clarity and better maintenance. All the snippets are included in [default.conf.erb](../src/logsearch-config/src/logstash-filters/default.conf.erb) file which is eventually used for parsing. The order of snippets is important, because fields parsed in one snippet are then used in another etc.

The parsing rules chain includes:

* [setup.conf](../src/logsearch-config/src/logstash-filters/snippets/setup.conf)

Contains general fields parsing. Sets such fields as _@input_, _@index_type_, _[@metadata][index]_ etc.

* [app.conf](../src/logsearch-config/src/logstash-filters/snippets/app.conf)

General parsing of application logs retrieved by *firehose-to-syslog* utility from CloudFoundry. Before shipping logs firehose-to-syslog wraps them to a JSON of a special format. The format varies for different event types. For possible event types and their formats see [*CloudFoundry dropsonde-protocol*](https://github.com/cloudfoundry/dropsonde-protocol/tree/master/events) which firehose-to-syslog uses.

Most of application _common fields_ are parsed in this snippet.

* [app-logmessage.conf](../src/logsearch-config/src/logstash-filters/snippets/app-logmessage.conf), [app-logmessage-app.conf](../src/logsearch-config/src/logstash-filters/snippets/app-logmessage-app.conf), [app-logmessage-rtr.conf](../src/logsearch-config/src/logstash-filters/snippets/app-logmessage-rtr.conf)

Parses _LogMessage_ events. 

Note that snippet *app-logmessage-app.conf* parses APP log messages - those **log lines emmitted by applications** during their work. The snippet parses several most popular log formats: **_JSON_**, **_Tomcat container logging format_** and **_Logback status lines logging format_**. See the snippet for details on parsing.

* [app-error.conf](../src/logsearch-config/src/logstash-filters/snippets/app-error.conf), [app-containermetric.conf](../src/logsearch-config/src/logstash-filters/snippets/app-containermetric.conf), [app-valuemetric.conf](../src/logsearch-config/src/logstash-filters/snippets/app-valuemetric.conf), [app-counterevent.conf](../src/logsearch-config/src/logstash-filters/snippets/app-counterevent.conf), [app-http.conf](../src/logsearch-config/src/logstash-filters/snippets/app-http.conf)

Parses *Error*, *ContainerMetric*, *ValueMetric*, *CounterEvent* and *HttpStartStop* events accordingly.

* [platform.conf](../src/logsearch-config/src/logstash-filters/snippets/platform.conf)

General parsing of CloudFoundry components logs. Parses logs based on Metron Agent [_format_](https://github.com/cloudfoundry/loggregator/blob/develop/jobs/metron_agent/templates/syslog_forwarder.conf.erb#L52-L54).

* [platform-haproxy.conf](../src/logsearch-config/src/logstash-filters/snippets/platform-haproxy.conf), [platform-uaa.conf](../src/logsearch-config/src/logstash-filters/snippets/platform-uaa.conf), [platform-vcap.conf](../src/logsearch-config/src/logstash-filters/snippets/platform-vcap.conf)

Parsing rules for CloudFoundry *haproxy*, *uaa* and other _vcap*_ components.

* [teardown.conf](../src/logsearch-config/src/logstash-filters/snippets/teardown.conf)

Performs fields post-processing and clean up.

</br>[<- prev page](deployment.md) | [next page ->](customization.md)
