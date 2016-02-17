# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/filters/grok"
require 'tempfile'
require "awesome_print"

describe LogStash::Filters::Grok do

  config <<-CONFIG
    filter {
      #{File.read("vendor/logsearch-boshrelease/src/logsearch-config/target/logstash-filters-default.conf")}
      #{File.read("target/logstash-filters-default.conf")}
    }
  CONFIG

  describe "Parse app_event messages" do

    #this test is so broken, it dosn't even...
      #sample("@type" => "syslog", "@message" => '<6>2015-10-16T05:47:15Z 17a45858-1a79-464d-acdb-09feb3e3221b doppler[1233]: {"cf_app_id":"99cb2fe3-0a35-404b-9318-c3189f760b0a","cf_app_name":"cf-app-events-logger","cf_org_id":"5296f502-4fd6-46c2-9b5f-223776627d03","cf_org_name":"system","cf_space_id":"4a61d055-6da2-4664-b696-b6ba351c9b18","cf_space_name":"logsearch","event_type":"LogMessage","level":"info","message_type":"OUT","msg":"{\"event_type\":\"AppEvent\",\"guid\":\"9050884d-732e-4aa9-822f-53728fd67c55\",\"type\":\"audit.app.update\",\"actor\":\"bb82ab7b-63b3-4265-8106-0b826146fcbf\",\"actor_type\":\"user\",\"actee\":\"99cb2fe3-0a35-404b-9318-c3189f760b0a\",\"actee_type\":\"app\",\"timestamp\":\"2015-10-16T05:46:15Z\",\"metadata\":{\"request\":{\"state\":\"STARTED\"}},\"space_guid\":\"4a61d055-6da2-4664-b696-b6ba351c9b18\",\"organization_guid\":\"5296f502-4fd6-46c2-9b5f-223776627d03\",\"actor_name\":\"admin\",\"actee_name\":\"cf-app-events-logger\",\"organization_name\":\"system\",\"space_name\":\"logsearch\",\"app_id\":\"99cb2fe3-0a35-404b-9318-c3189f760b0a\",\"app_name\":\"cf-app-events-logger\"}","origin":"dea_logging_agent","source_instance":"0","source_type":"App","time":"2015-10-16T05:47:15Z","timestamp":1444974435694086109}","@version":"1","@timestamp":"2015-10-16T05:47:15.695Z","host":"127.0.0.1","type":"syslog"}') do

        ##puts subject['@metadata'].to_hash.to_yaml
        ##puts subject.to_hash.to_yaml
        ##puts subject['app_event'].to_hash.to_yaml

        #ap subject
        ##insist { subject["@tags"] } == [ 'syslog_standard', 'firehose', 'app_event' ]
        #insist { subject['@metadata']["type"] } == "app_event"
        #insist { subject["@timestamp"] } == Time.iso8601("2015-10-16T05:46:15Z")

        #insist { subject["@source"]["app"]["id"] } == "99cb2fe3-0a35-404b-9318-c3189f760b0a"
        #insist { subject["@source"]["app"]["name"] } == "cf-app-events-logger"
        #insist { subject["@source"]["space"]["id"] } == "4a61d055-6da2-4664-b696-b6ba351c9b18"
        #insist { subject["@source"]["space"]["name"] } == "logsearch"
        #insist { subject["@source"]["org"]["id"] } == "5296f502-4fd6-46c2-9b5f-223776627d03"
        #insist { subject["@source"]["org"]["name"] } == "system"

        #insist { subject["@source"]["component"] } == "AppEvent"
        #insist { subject["@source"]["instance"] } == 0
        #insist { subject["@source"]["name"] } == "AppEvent/0"

        #insist { subject["app_event"]["type"] } == "audit.app.update"
        #insist { subject["app_event"]["metadata"] } == {"request"=>{"state"=>"STARTED"}}
        #insist { subject["@message"] } == 'audit.app.update {"request"=>{"state"=>"STARTED"}}'

      #end

    end #describe Parse app_event messages

end
