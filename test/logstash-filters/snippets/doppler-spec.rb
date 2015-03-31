# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/filters/grok"

describe LogStash::Filters::Grok do

  config <<-CONFIG
    filter {
      #{File.read("vendor/logsearch-boshrelease/logstash-filters-default.conf")} # This simulates the default parsing that logsearch v19+ does
      #{File.read("target/logstash-filters-default.conf")}
    }
  CONFIG

  describe "Parse Cloud Foundry doppler messages" do

    describe "invalid json" do
      sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:24:23Z jumpbox.xxxxxxx.com doppler[6375]: {"invalid }') do
        #puts subject.to_hash.to_yaml

        insist { subject["tags"] } == [ 'syslog_standard', 'fail/cloudfoundry/doppler/jsonparsefailure_of_syslog_message' ]
     
      end
    end

    describe "should always have an event_type field" do
        describe "should default to event_type:LogMessage when missing" do
          sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:24:23Z jumpbox.xxxxxxx.com doppler[6375]: {"cf_app_id":"b732c465-0536-4014-b922-165eb38857b2","level":"info","message_type":"OUT","msg":"Stopped app instance (index 0) with guid b732c465-0536-4014-b922-165eb38857b2","source_instance":"7","source_type":"DEA","time":"2015-03-17T01:24:23Z"}') do
            #puts subject.to_hash.to_yaml

            insist { subject["event_type"] } == "LogMessage"
         
          end
      end
    end

    describe "source_type=DEA" do
      sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:24:23Z jumpbox.xxxxxxx.com doppler[6375]: {"cf_app_id":"b732c465-0536-4014-b922-165eb38857b2","level":"info","message_type":"OUT","msg":"Stopped app instance (index 0) with guid b732c465-0536-4014-b922-165eb38857b2","source_instance":"7","source_type":"DEA","time":"2015-03-17T01:24:23Z"}') do
        #puts subject.to_hash.to_yaml

        insist { subject["tags"] } == [ 'syslog_standard', 'cloudfoundry_doppler' ]
        insist { subject["@type"] } == "cloudfoundry_doppler"
        insist { subject["@timestamp"] } == Time.iso8601("2015-03-17T01:24:23.000Z")
        insist { subject["@message"] } == '{"cf_app_id":"b732c465-0536-4014-b922-165eb38857b2","level":"info","message_type":"OUT","msg":"Stopped app instance (index 0) with guid b732c465-0536-4014-b922-165eb38857b2","source_instance":"7","source_type":"DEA","time":"2015-03-17T01:24:23Z"}'
        insist { subject["@source.host"] } == "jumpbox.xxxxxxx.com"

        insist { subject["cf_app_id"] } == "b732c465-0536-4014-b922-165eb38857b2"
        insist { subject["level"] } == "info"
        insist { subject["message_type"] } == "OUT"
        insist { subject["source_type"] } == "DEA"
        insist { subject["source_instance"] } == "7"
        insist { subject["msg"] } == "Stopped app instance (index 0) with guid b732c465-0536-4014-b922-165eb38857b2"

      end
    end

    describe "source_type=RTR" do
      sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:22:43Z jumpbox.xxxxxxx.com doppler[6375]: {"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"OUT","msg":"cf-env-test.xxxxxxx.com - [17/03/2015:01:21:42 +0000] \"GET / HTTP/1.1\" 200 5087 \"-\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36\" 10.10.0.71:45298 x_forwarded_for:\"184.169.44.78, 192.168.16.3, 184.169.44.78, 10.10.0.71\" vcap_request_id:c66716aa-fef1-482f-55c3-133be3ed8de7 response_time:0.003644458 app_id:ec2d33f6-fd1c-49a5-9a90-031454d1f1ac\n","source_instance":"0","source_type":"RTR","time":"2015-03-17T01:22:43Z"}') do
        #puts subject.to_hash.to_yaml

        insist { subject["tags"] } == [ 'syslog_standard', 'cloudfoundry_doppler' ]
        insist { subject["@type"] } == "cloudfoundry_doppler"
        insist { subject["@message"] } == '{"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"OUT","msg":"cf-env-test.xxxxxxx.com - [17/03/2015:01:21:42 +0000] \"GET / HTTP/1.1\" 200 5087 \"-\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36\" 10.10.0.71:45298 x_forwarded_for:\"184.169.44.78, 192.168.16.3, 184.169.44.78, 10.10.0.71\" vcap_request_id:c66716aa-fef1-482f-55c3-133be3ed8de7 response_time:0.003644458 app_id:ec2d33f6-fd1c-49a5-9a90-031454d1f1ac\n","source_instance":"0","source_type":"RTR","time":"2015-03-17T01:22:43Z"}'
        insist { subject["@source.host"] } == "jumpbox.xxxxxxx.com"

        #timestamp should come from the inner RTR timestamp
        insist { subject["@timestamp"] } == Time.iso8601("2015-03-17T01:21:42Z")

        insist { subject["cf_app_id"] } == "ec2d33f6-fd1c-49a5-9a90-031454d1f1ac"
        insist { subject["level"] } == "info"
        insist { subject["message_type"] } == "OUT"
        insist { subject["source_type"] } == "RTR"

        insist { subject["verb"] } == "GET"
        insist { subject["path"] } == "/"
        insist { subject["http_spec"] } == "HTTP/1.1"
        insist { subject["status"] } == 200
        insist { subject["body_bytes_sent"] } == 5087
        insist { subject["referer"] } == "-"
        insist { subject["http_user_agent"] } == "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36"
        
        insist { subject["remote_addr"] } == "184.169.44.78"
        insist { subject["x_forwarded_for"] } == [ "184.169.44.78", "192.168.16.3", "184.169.44.78", "10.10.0.71" ]
        insist { subject["geoip"]["location"] } == [ -118.8935, 34.14439999999999 ]

        insist { subject["vcap_request_id"] } == "c66716aa-fef1-482f-55c3-133be3ed8de7"
        insist { subject["response_time"] } == 0.003644458

      end
    end

    describe "message_type=ERR" do
      sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:22:43Z jumpbox.xxxxxxx.com doppler[6375]: {"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"ERR","msg":"184.169.44.78, 192.168.16.3, 184.169.44.78, 10.10.0.71 - - [17/Mar/2015 01:21:42] \"GET / HTTP/1.1\" 200 5087 0.0022","source_instance":"0","source_type":"App","time":"2015-03-17T01:22:43Z"}') do

        insist { subject["tags"] } == [ 'syslog_standard', 'cloudfoundry_doppler' ]
        insist { subject["@type"] } == "cloudfoundry_doppler"
        insist { subject["@message"] } == '{"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"ERR","msg":"184.169.44.78, 192.168.16.3, 184.169.44.78, 10.10.0.71 - - [17/Mar/2015 01:21:42] \"GET / HTTP/1.1\" 200 5087 0.0022","source_instance":"0","source_type":"App","time":"2015-03-17T01:22:43Z"}'
        insist { subject["@source.host"] } == "jumpbox.xxxxxxx.com"

        #timestamp should come from the inner RTR timestamp
        insist { subject["@timestamp"] } == Time.iso8601("2015-03-17T01:22:43Z")

        insist { subject["cf_app_id"] } == "ec2d33f6-fd1c-49a5-9a90-031454d1f1ac"
        insist { subject["level"] } == "info"
        insist { subject["message_type"] } == "ERR"
        insist { subject["source_type"] } == "App"
        insist { subject["source_instance"] } == "0"
        insist { subject["msg"] } == '184.169.44.78, 192.168.16.3, 184.169.44.78, 10.10.0.71 - - [17/Mar/2015 01:21:42] "GET / HTTP/1.1" 200 5087 0.0022'
   
      end

      sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:22:40Z jumpbox.xxxxxxx.com doppler[6375]: {"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"ERR","msg":"W, [2015-03-17T01:21:39.739322 #31] WARN -- : attack prevented by Rack::Protection::IPSpoofing","source_instance":"0","source_type":"App","time":"2015-03-17T01:22:40Z"}') do

       # puts subject.to_hash.to_yaml

        insist { subject["tags"] } == [ 'syslog_standard', 'cloudfoundry_doppler' ]
        insist { subject["@type"] } == "cloudfoundry_doppler"
        insist { subject["@message"] } == '{"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"ERR","msg":"W, [2015-03-17T01:21:39.739322 #31] WARN -- : attack prevented by Rack::Protection::IPSpoofing","source_instance":"0","source_type":"App","time":"2015-03-17T01:22:40Z"}'
        insist { subject["@source.host"] } == "jumpbox.xxxxxxx.com"

        #timestamp should come from the inner RTR timestamp
        insist { subject["@timestamp"] } == Time.iso8601("2015-03-17T01:22:40Z")

        insist { subject["cf_app_id"] } == "ec2d33f6-fd1c-49a5-9a90-031454d1f1ac"
        insist { subject["level"] } == "info"
        insist { subject["message_type"] } == "ERR"
        insist { subject["source_type"] } == "App"
        insist { subject["source_instance"] } == "0"
        insist { subject["msg"] } == 'W, [2015-03-17T01:21:39.739322 #31] WARN -- : attack prevented by Rack::Protection::IPSpoofing'
   
      end
      
    end
    
  end

end
