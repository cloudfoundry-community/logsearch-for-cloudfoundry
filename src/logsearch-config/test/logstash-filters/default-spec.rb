# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require 'logstash/filters/grok'

describe LogStash::Filters::Grok do

  describe 'Filters behave when combined' do

    config <<-CONFIG
      filter {
        #{File.read('target/logstash-filters-default.conf')}
      }
    CONFIG

    describe 'app_event' do

        sample("@type" => "syslog", "syslog_program" => "doppler", "syslog_message" => '{"cf_app_id":"9739bf26-5f7c-44e5-9740-22fb65244df9","cf_app_name":"events","cf_org_id":"5296f502-4fd6-46c2-9b5f-223776627d03","cf_org_name":"system","cf_space_id":"4a61d055-6da2-4664-b696-b6ba351c9b18","cf_space_name":"logsearch","event_type":"LogMessage","level":"info","message_type":"OUT","msg":"{\"event_type\":\"AppEvent\",\"guid\":\"e09ab4f2-1b59-4374-8a1c-e4039aea16a5\",\"type\":\"audit.app.update\",\"actor\":\"bb82ab7b-63b3-4265-8106-0b826146fcbf\",\"actor_type\":\"user\",\"actee\":\"9739bf26-5f7c-44e5-9740-22fb65244df9\",\"actee_type\":\"app\",\"timestamp\":\"2015-10-14T16:02:30Z\",\"metadata\":{\"request\":{\"state\":\"STARTED\"}},\"space_guid\":\"4a61d055-6da2-4664-b696-b6ba351c9b18\",\"organization_guid\":\"5296f502-4fd6-46c2-9b5f-223776627d03\"}","origin":"dea_logging_agent","source_instance":"0","source_type":"App","time":"2015-10-14T16:03:28Z","timestamp":1444838608566597106}') do

            # puts subject['app_event'].to_hash.to_yaml
            
             insist { subject["tags"] } == [ 'cloudfoundry_doppler', 'app_event' ]
             insist { subject["@type"] } == "app_event"

             insist { subject["app_event"]["event_type"] } == "AppEvent"
             insist { subject["app_event"]["type"] } == "audit.app.update"
        end

    end #describe app_event

  end #describe 'Filters behave when combined'

end
