# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/filters/grok"
require 'tempfile'

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

      sample("@type" => "syslog", '@message' => '<6>2015-08-17T10:02:18Z canopy-labs.example.com doppler[6375]: {"cf_app_id":"e3c4579a-d3bd-4857-9294-dc6348735848","cf_app_name":"logs","cf_org_id":"c59cb38f-f40a-42b4-ad6c-053413e4b3f3","cf_org_name":"cip-sys","cf_space_id":"637da72a-59ad-4773-987c-72f2d9a53fae","cf_space_name":"elk-for-pcf","event_type":"LogMessage","level":"info","message_type":"OUT","msg":"logs.sys.demo.labs.cf.canopy-cloud.com - [17/08/2015:10:02:17 +0000] \"POST /elasticsearch/_mget?timeout=0\u0026ignore_unavailable=true\u0026preference=1439805736876 HTTP/1.1\" 200 86 352 \"https://logs.sys.demo.labs.cf.canopy-cloud.com/\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:40.0) Gecko/20100101 Firefox/40.0\" 10.0.16.5:35928 x_forwarded_for:\"94.197.120.100\" vcap_request_id:555e9aab-f0bb-49f0-4539-ec257d917435 response_time:0.006633385 app_id:e3c4579a-d3bd-4857-9294-dc6348735848\n","origin":"router__0","source_instance":"0","source_type":"RTR","time":"2015-08-17T10:02:17Z","timestamp":1439805737627585338}') do
		#puts subject.to_hash.to_yaml
        
		insist { subject["tags"] } == [ 'syslog_standard', 'cloudfoundry_doppler' ]

		insist { subject["status"] } == 200
		insist { subject["request_bytes_received"] } == 86
		insist { subject["body_bytes_sent"] } == 352
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
   
    describe "Decorate app logs with name, org and space" do
      sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:22:43Z jumpbox.xxxxxxx.com doppler[6375]: {"cf_app_name":"myappname","cf_space_name":"myspacename","cf_org_name":"myorgname","cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"ERR","msg":"184.169.44.78, 192.168.16.3, 184.169.44.78, 10.10.0.71 - - [17/Mar/2015 01:21:42] \"GET / HTTP/1.1\" 200 5087 0.0022","source_instance":"0","source_type":"App","time":"2015-03-17T01:22:43Z"}') do
        #puts subject.to_hash.to_yaml

        insist { subject["tags"] } == [ 'syslog_standard', 'cloudfoundry_doppler' ]
        insist { subject["@type"] } == "cloudfoundry_doppler"

        insist { subject["cf_app_id"] } == "ec2d33f6-fd1c-49a5-9a90-031454d1f1ac"

        insist { subject["cf_app_name"] } == "myappname"
        insist { subject["cf_space_name"] } == "myspacename"
        insist { subject["cf_org_name"] } == "myorgname"
      end
      
    end 
  end

end

