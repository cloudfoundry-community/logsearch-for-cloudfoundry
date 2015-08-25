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

def convert_to_erb ( type, doc )
  erb_string = ""

  case type
  when "search"
    searchSourceJSON = JSON.parse(doc["kibanaSavedObjectMeta"]["searchSourceJSON"])
    doc["kibanaSavedObjectMeta"]["searchSourceJSON"] = "REPLACE_WITH_searchSourceJSON"
    erb_string = "<% require 'json' %>\n#{JSON.pretty_generate(doc)}"
    erb_string = erb_string.sub(/REPLACE_WITH_searchSourceJSON/, erb_to_render_stringified_json(searchSourceJSON) )
  when "visualization"
    searchSourceJSON = JSON.parse(doc["kibanaSavedObjectMeta"]["searchSourceJSON"])
    doc["kibanaSavedObjectMeta"]["searchSourceJSON"] = "REPLACE_WITH_searchSourceJSON"
    visStateJSON = JSON.parse(doc["visState"])
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

export_kibana_config es_host, 'index-pattern' ,'[logstash-]YYYY.MM.DD' # For CF App dashboards
# export_kibana_config es_host, 'index-pattern' ,'logstash-*' # For CF component dashboards

export_kibana_config es_host, 'search', 'LogMessages'
export_kibana_config es_host, 'search', 'LogMessages-RTR'
export_kibana_config es_host, 'search', 'LogMessages-ERROR'

export_kibana_config es_host, 'visualization', 'LogMessages-ERROR-by-cf_app_name'
export_kibana_config es_host, 'visualization', 'LogMessages-ERROR-by-time'

export_kibana_config es_host, 'dashboard', 'CF-App-ERRORs'

# Redis
export_kibana_config es_host, 'dashboard', 'Redis-dashboard'
export_kibana_config es_host, 'visualization', 'Redis-log-severity'
export_kibana_config es_host, 'visualization', 'Redis-source-hosts'
export_kibana_config es_host, 'visualization', 'Redis-syslog-programs'
export_kibana_config es_host, 'search', 'Redis-logs-from-redis-and-redis-broker'

# RabbitMQ
export_kibana_config es_host, 'dashboard', 'RabbitMQ-dashboard'
export_kibana_config es_host, 'search', 'Rabbitmq-logs-from-rabbitmq,-HAProxy-and-rabbit-broker'
export_kibana_config es_host, 'visualization', 'RabbitMQ-source-hosts'
export_kibana_config es_host, 'visualization', 'RabbitMQ-all-logs'
