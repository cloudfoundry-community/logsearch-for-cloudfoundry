# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/filters/grok"
require 'tempfile'

#Lookup using: cf curl "/v2/apps/$APP_UUID?inline-relations-depth=2" | jq --compact-output '. | { cf_app_id: .metadata.guid, cf_app_name: .entity.name , cf_space_id: .entity.space.metadata.guid , cf_space_name: .entity.space.entity.name , cf_org_id: .entity.space.entity.organization.metadata.guid , cf_org_name: .entity.space.entity.organization.entity.name }'
DICTIONARY = <<EOD
'9af4f832-32cf-47c1-bce8-f2e852ea0730': '{"cf_app_id":"9af4f832-32cf-47c1-bce8-f2e852ea0730","cf_app_name":"app-logs","cf_space_id":"5c98b860-f5d2-444c-b923-d91b277b5269","cf_space_name":"production","cf_org_id":"8005f45b-76d9-4038-8ca1-9e0a85ed5be0","cf_org_name":"system"}'
'54967f0c-5069-4428-83de-84f86c1286e2': '{"cf_app_id":"54967f0c-5069-4428-83de-84f86c1286e2","cf_app_name":"devApp1","cf_space_id":"a871a722-cad2-4d46-8061-2c9b728b7d8f","cf_space_name":"development","cf_org_id":"8005f45b-76d9-4038-8ca1-9e0a85ed5be0","cf_org_name":"system"}'
'2769b9da-5ad7-4bbc-a337-d9fc14ed355e': '{"cf_app_id":"2769b9da-5ad7-4bbc-a337-d9fc14ed355e","cf_app_name":"testApp1","cf_space_id":"182d42fe-eebf-4826-9127-38a49fac8e91","cf_space_name":"test","cf_org_id":"8005f45b-76d9-4038-8ca1-9e0a85ed5be0","cf_org_name":"system"}'
'd7d702c9-7863-4d16-a375-be7cd960022d': '{"cf_app_id":"d7d702c9-7863-4d16-a375-be7cd960022d","cf_app_name":"prodApp1","cf_space_id":"5c98b860-f5d2-444c-b923-d91b277b5269","cf_space_name":"production","cf_org_id":"8005f45b-76d9-4038-8ca1-9e0a85ed5be0","cf_org_name":"system"}'
'ec2d33f6-fd1c-49a5-9a90-031454d1f1ac': '{"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","cf_app_name":"myappname","cf_space_id":"5c98b860-f5d2-444c-b923-XXXXX","cf_space_name":"myspacename","cf_org_id":"8005f45b-76d9-4038-8ca1-YYYYY","cf_org_name":"myorgname"}'
EOD

describe LogStash::Filters::Grok do
 
  #Replace referenced cf-app-space-org-dictionary.yml path with path to test dictionary
  test_dictionary = Tempfile.new('TEST-cf-app-space-org-dictionary.yml')
  test_dictionary.write(DICTIONARY)
  test_dictionary.close

  filters_path = "target/logstash-filters-default.conf"
  filters = File.read(filters_path) 
  updated_filters = filters.gsub!("/var/vcap/store/cf_app_details_cache/cf_app_space_org_dictionary.yml", test_dictionary.path)
  File.open("#{filters_path}-with-test-dictionary", "w") { |file| file << updated_filters }

  config <<-CONFIG
    filter {
      #{File.read("vendor/logsearch-boshrelease/logstash-filters-default.conf")} # This simulates the default parsing that logsearch v19+ does
      #{File.read("target/logstash-filters-default.conf-with-test-dictionary")}
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
   
    describe "Decorate app logs with name, org and space" do
      sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:22:43Z jumpbox.xxxxxxx.com doppler[6375]: {"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"ERR","msg":"184.169.44.78, 192.168.16.3, 184.169.44.78, 10.10.0.71 - - [17/Mar/2015 01:21:42] \"GET / HTTP/1.1\" 200 5087 0.0022","source_instance":"0","source_type":"App","time":"2015-03-17T01:22:43Z"}') do
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

