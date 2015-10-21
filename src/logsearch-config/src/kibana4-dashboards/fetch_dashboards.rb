#!/usr/bin/env ruby
require 'cgi'
require 'json'
require 'httparty'

es_host = ARGV[0]

def fetch_kibana_config ( es_host, type, name )
  escaped_name = CGI.escape(name)
  url = "http://#{es_host}/.kibana/#{type}/#{escaped_name}/_source"
  HTTParty.get url
end

def erb_to_render_stringified_json( json )
  %Q[<%= JSON.parse(<<'ENDOFFJSON').to_json.gsub(/\"/) { '\\"' }\n#{JSON.pretty_generate(json).gsub(/^/,'    ')}
ENDOFFJSON\n%>]
end

def escape_embedded_doublequote(str)
  str.gsub("\\\"", "_eQT_")
end

def escape_embedded_newline(str)
  str.gsub("\n", "_eLF_")
end

def convert_to_erb ( type, doc )
  erb_string = ""

  case type
  when "search"
    searchSourceJSON = JSON.parse(escape_embedded_doublequote(doc["kibanaSavedObjectMeta"]["searchSourceJSON"]))
    doc["kibanaSavedObjectMeta"]["searchSourceJSON"] = "REPLACE_WITH_searchSourceJSON"
    erb_string = "<% require 'json' %>\n#{JSON.pretty_generate(doc)}"
    erb_string = erb_string.sub(/REPLACE_WITH_searchSourceJSON/, erb_to_render_stringified_json(searchSourceJSON) )
  when "visualization"
    searchSourceJSON = JSON.parse(doc["kibanaSavedObjectMeta"]["searchSourceJSON"])
    doc["kibanaSavedObjectMeta"]["searchSourceJSON"] = "REPLACE_WITH_searchSourceJSON"
    visStateJSON = JSON.parse(doc["visState"])
    if visStateJSON["type"] == "markdown"
      #If we have a mardown viz on our hands, we must be sure to escape '\\n' in visStateJSON
      visStateJSON["params"]["markdown"] = escape_embedded_newline(visStateJSON["params"]["markdown"])
    end
    doc["visState"]= "REPLACE_WITH_visStateJSON"
    erb_string = "<% require 'json' %>\n#{JSON.pretty_generate(doc)}"
    erb_string = erb_string.sub(/REPLACE_WITH_searchSourceJSON/, erb_to_render_stringified_json(searchSourceJSON) )
    erb_string = erb_string.sub(/REPLACE_WITH_visStateJSON/, erb_to_render_stringified_json(visStateJSON) )
  when "index-pattern"
    fieldsJSON = JSON.parse(doc["fields"])
    doc["fields"]= "REPLACE_WITH_fieldsJSON"
    erb_string = "<% require 'json' %>\n#{JSON.pretty_generate(doc)}"
    erb_string = erb_string.sub(/REPLACE_WITH_fieldsJSON/, erb_to_render_stringified_json(fieldsJSON) )
  when "dashboard"
    searchSourceJSON = JSON.parse(doc["kibanaSavedObjectMeta"]["searchSourceJSON"])
    doc["kibanaSavedObjectMeta"]["searchSourceJSON"] = "REPLACE_WITH_searchSourceJSON"
    panelsJSON = JSON.parse(doc["panelsJSON"])
    doc["panelsJSON"] = "REPLACE_WITH_panelsJSON"
    erb_string = "<% require 'json' %>\n#{JSON.pretty_generate(doc)}"
    erb_string = erb_string.sub(/REPLACE_WITH_searchSourceJSON/, erb_to_render_stringified_json(searchSourceJSON) )
    erb_string = erb_string.sub(/REPLACE_WITH_panelsJSON/, erb_to_render_stringified_json(panelsJSON) )
  else
    erb_string = JSON.pretty_generate(doc)
  end
  "#{erb_string}\n"
end

def export_kibana_config ( es_host, type, name )
  puts "Exporting http://#{es_host}/.kibana/#{type}/#{name} to #{type}/#{name}.json.erb"
  File.write( "#{type}/#{name}.json.erb", convert_to_erb( type, fetch_kibana_config( es_host, type, name ) ) )
end

export_kibana_config es_host, 'index-pattern' ,'[logs-app-]YYYY.MM.DD' 
export_kibana_config es_host, 'index-pattern' ,'[logs-platform-]YYYY.MM.DD' 

export_kibana_config es_host, 'config' ,'4.2.0-beta2'

## App location
export_kibana_config es_host, 'dashboard', 'CF-App-Location'
export_kibana_config es_host, 'visualization', 'RTR-requests-map'
export_kibana_config es_host, 'visualization', 'Top-25-Apps-by-log-count'
export_kibana_config es_host, 'visualization', 'RTR-requests-by-timezone'
export_kibana_config es_host, 'search', 'app-all'

#
## CF App RTR
#export_kibana_config es_host, 'dashboard', 'CF-App-RTR'
#export_kibana_config es_host, 'visualization', 'LogMessages-RTR:-Count'
#export_kibana_config es_host, 'visualization', 'LogMessages-RTR:-App-names'
#export_kibana_config es_host, 'visualization', 'LogMessages-RTR:-Source-IP'
#export_kibana_config es_host, 'visualization', 'LogMessages-RTR:-Latency'
#export_kibana_config es_host, 'visualization', 'LogMessages-RTR:-HTTP-status'
#export_kibana_config es_host, 'visualization', 'LogMessages-RTR:-Top-25-UserAgents'
#export_kibana_config es_host, 'search', 'LogMessages-RTR'
#
## CF App ERRORS
#export_kibana_config es_host, 'visualization', 'LogMessages-ERROR-by-cf_app_name'
#export_kibana_config es_host, 'visualization', 'LogMessages-ERROR-by-time'
#export_kibana_config es_host, 'dashboard', 'CF-App-ERRORs'
#export_kibana_config es_host, 'search', 'LogMessages-ERROR'
#
## CF
#export_kibana_config es_host, 'dashboard', 'CF'
#export_kibana_config es_host, 'visualization', 'CF:-Job-by-Log-Level'
#export_kibana_config es_host, 'visualization', 'CF:-Jobs'
#export_kibana_config es_host, 'visualization', 'CF:-Log-Level-by-Job-by-Template'
#export_kibana_config es_host, 'search', 'tags:cloudfoundry_vcap'
#
## Redis
#export_kibana_config es_host, 'dashboard', 'Redis-dashboard'
#export_kibana_config es_host, 'visualization', 'Redis-log-severity'
#export_kibana_config es_host, 'visualization', 'Redis-source-hosts'
#export_kibana_config es_host, 'visualization', 'Redis-syslog-programs'
#export_kibana_config es_host, 'search', 'Redis-logs-from-redis-and-redis-broker'
#
## RabbitMQ
#export_kibana_config es_host, 'dashboard', 'RabbitMQ-dashboard'
#export_kibana_config es_host, 'search', 'Rabbitmq-logs-from-rabbitmq,-HAProxy-and-rabbit-broker'
#export_kibana_config es_host, 'visualization', 'RabbitMQ-source-hosts'
#export_kibana_config es_host, 'visualization', 'RabbitMQ-all-logs'
#
##UAA Audit
#export_kibana_config es_host, 'dashboard', 'UAA-Audit'
#export_kibana_config es_host, 'search', 'UAA-Audit-*'
#export_kibana_config es_host, 'visualization', 'UAA-Audit'
#export_kibana_config es_host, 'visualization', 'UAA-Audit-audit_event_type'
#export_kibana_config es_host, 'visualization', 'UAA-Audit-geoip-login'
#
## Overview
#export_kibana_config es_host, 'dashboard', 'Overview'
#export_kibana_config es_host, 'visualization', 'Overview-welcome'
#export_kibana_config es_host, 'visualization', 'Overview-Data-services'
#export_kibana_config es_host, 'visualization', 'Overview-app-logs'
#export_kibana_config es_host, 'visualization', 'Overview-CF-logs'
#
## Mysql
#export_kibana_config es_host, 'dashboard', 'Mysql-dashboard'
#export_kibana_config es_host, 'search', 'Mysql-logs-from-mysql-and-mysql-broker'
#export_kibana_config es_host, 'visualization', 'Mysql-syslog-programs'
#export_kibana_config es_host, 'visualization', 'Mysql-source-hosts'
#export_kibana_config es_host, 'visualization', 'Mysql-log-severity'
#
## CF Apps
#export_kibana_config es_host, 'dashboard', 'CF-Apps'
#export_kibana_config es_host, 'search', 'LogMessages'
#export_kibana_config es_host, 'visualization', 'LogMessages-Count-by-source_type'
#export_kibana_config es_host, 'visualization', 'LogMessages-response_time'
#export_kibana_config es_host, 'visualization', 'LogMessages-by-cf_app_name'
#
# Platform - Metrics 
export_kibana_config es_host, 'dashboard', 'Platform-Metrics'
export_kibana_config es_host, 'search', 'metric'
export_kibana_config es_host, 'visualization', 'metric-components'
export_kibana_config es_host, 'visualization', 'metric-keys'
export_kibana_config es_host, 'visualization', 'metric-median-of-value_int'

# Platform - DEA Health 
export_kibana_config es_host, 'dashboard', 'Platform-DEA-Health'
export_kibana_config es_host, 'search', 'platform-metrics-available_disk_ratio'
export_kibana_config es_host, 'search', 'platform-metrics-available_memory_ratio'
export_kibana_config es_host, 'search', 'platform-metrics-cpu_load_avg'
export_kibana_config es_host, 'search', 'platform-metrics-DEA-can_stage'
export_kibana_config es_host, 'search', 'platform-metrics-DEA-reservable_stagers'
export_kibana_config es_host, 'visualization', 'DEA-can-stage-questionmark-'
export_kibana_config es_host, 'visualization', 'DEA-reservable-stagers'
export_kibana_config es_host, 'visualization', 'CPU-load-average'
export_kibana_config es_host, 'visualization', 'Available-memory-%'
export_kibana_config es_host, 'visualization', 'Available-disk-%'

# App - Events 
export_kibana_config es_host, 'dashboard', 'App-Events'
export_kibana_config es_host, 'search', 'AppEvent'
export_kibana_config es_host, 'visualization', 'App-events'

