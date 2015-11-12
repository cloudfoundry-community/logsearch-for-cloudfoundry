# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/filters/grok"
require 'tempfile'

describe LogStash::Filters::Grok do

  config <<-CONFIG
    filter {
      #{File.read("vendor/logsearch-boshrelease/src/logsearch-filters-common/target/logstash-filters-default.conf")}
      #{File.read("target/logstash-filters-default.conf")}
    }
  CONFIG

  describe "Parse Cloud Foundry doppler messages" do

    describe "invalid json" do
      sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:24:23Z jumpbox.xxxxxxx.com doppler[6375]: {"invalid }') do
        #puts subject.to_hash.to_yaml

        insist { subject["@tags"] } == [ 'syslog_standard', 'fail/cloudfoundry/firehose/jsonparsefailure_of_syslog_message' ]

      end
    end

    describe "should always have an [@metadata][type] field" do
        describe "should default to LogMessage when missing" do
          sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:24:23Z jumpbox.xxxxxxx.com doppler[6375]: {"cf_app_id":"b732c465-0536-4014-b922-165eb38857b2","level":"info","message_type":"OUT","msg":"Stopped app instance (index 0) with guid b732c465-0536-4014-b922-165eb38857b2","source_instance":"7","source_type":"DEA","time":"2015-03-17T01:24:23Z"}') do
            #puts subject.to_hash.to_yaml

            insist { subject["@metadata"]["type"] } == "LogMessage"

          end
      end
    end

    describe "source_type=DEA" do
      sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:24:23Z jumpbox.xxxxxxx.com doppler[6375]: {"cf_app_id":"b732c465-0536-4014-b922-165eb38857b2","level":"info","message_type":"OUT","msg":"Stopped app instance (index 0) with guid b732c465-0536-4014-b922-165eb38857b2","source_instance":"7","source_type":"DEA","time":"2015-03-17T01:24:23Z"}') do
        #puts subject.to_hash.to_yaml

        insist { subject["@tags"] } == [ 'syslog_standard', 'firehose' ]
        insist { subject['@metadata']["type"] } == "LogMessage"
        insist { subject["@timestamp"] } == Time.iso8601("2015-03-17T01:24:23.000Z")

        insist { subject["@level"] } == "INFO"
        insist { subject["@source"]["app"]["id"] } == "b732c465-0536-4014-b922-165eb38857b2"
        insist { subject["@source"]["message_type"] } == "OUT"
        insist { subject["@source"]["component"] } == "DEA"
        insist { subject["@source"]["instance"] } == 7
        insist { subject["@source"]["name"] } == "DEA/7"
        insist { subject["@message"] } == "Stopped app instance (index 0) with guid b732c465-0536-4014-b922-165eb38857b2"

      end
    end #describe "source_type=DEA"

    describe "source_type=RTR" do
      sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:22:43Z jumpbox.xxxxxxx.com doppler[6375]: {"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"OUT","msg":"cf-env-test.xxxxxxx.com - [17/03/2015:01:21:42 +0000] \"GET / HTTP/1.1\" 200 5087 \"-\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36\" 10.10.0.71:45298 x_forwarded_for:\"184.169.44.78, 192.168.16.3, 184.169.44.78, 10.10.0.71\" vcap_request_id:c66716aa-fef1-482f-55c3-133be3ed8de7 response_time:0.3644458 app_id:ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","source_instance":"0","source_type":"RTR","time":"2015-03-17T01:22:43Z"}') do
        #puts subject.to_hash.to_yaml

        insist { subject["@tags"].sort } == [ 'syslog_standard', 'firehose', "RTR" ].sort
        insist { subject["@metadata"]["type"] } == "LogMessage"
        insist { subject["@message"] } == 'cf-env-test.xxxxxxx.com - [17/03/2015:01:21:42 +0000] "GET / HTTP/1.1" 200 5087 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36" 10.10.0.71:45298 x_forwarded_for:"184.169.44.78, 192.168.16.3, 184.169.44.78, 10.10.0.71" vcap_request_id:c66716aa-fef1-482f-55c3-133be3ed8de7 response_time:0.3644458 app_id:ec2d33f6-fd1c-49a5-9a90-031454d1f1ac'

        #timestamp should come from the inner RTR timestamp
        insist { subject["@timestamp"] } == Time.iso8601("2015-03-17T01:21:42Z")

        insist { subject["@level"] } == "INFO"
        insist { subject["@source"]["app"]["id"] } == "ec2d33f6-fd1c-49a5-9a90-031454d1f1ac"
        insist { subject["@source"]["message_type"] } == "OUT"
        insist { subject["@source"]["component"] } == "RTR"

        insist { subject["RTR"]["verb"] } == "GET"
        insist { subject["RTR"]["path"] } == "/"
        insist { subject["RTR"]["http_spec"] } == "HTTP/1.1"
        insist { subject["RTR"]["status"] } == 200
        insist { subject["RTR"]["body_bytes_sent"] } == 5087
        insist { subject["RTR"]["referer"] } == "-"
        insist { subject["RTR"]["http_user_agent"] } == "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36"

        insist { subject["RTR"]["remote_addr"] } == "184.169.44.78"
        insist { subject["RTR"]["x_forwarded_for"] } == [ "184.169.44.78", "192.168.16.3", "184.169.44.78", "10.10.0.71" ]
        insist { subject["geoip"]["location"] } == [ -118.8935, 34.14439999999999 ]

        insist { subject["RTR"]["vcap_request_id"] } == "c66716aa-fef1-482f-55c3-133be3ed8de7"
        insist { subject["RTR"]["response_time_ms"] } == 364
      end

     sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:22:43Z jumpbox.xxxxxxx.com doppler[6375]: {"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"OUT","msg":"cf-env-test.xxxxxxx.com - [17/03/2015:01:21:42 +0000] \"GET / HTTP/1.1\" 200 5087 \"-\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36\" 10.10.0.71:45298 x_forwarded_for:\"-\" vcap_request_id:c66716aa-fef1-482f-55c3-133be3ed8de7 response_time:0.003644458 app_id:ec2d33f6-fd1c-49a5-9a90-031454d1f1ac\n","source_instance":"0","source_type":"RTR","time":"2015-03-17T01:22:43Z"}') do
        #puts subject.to_hash.to_yaml

       insist { subject['RTR']["x_forwarded_for"] } == [ "-" ]
       insist { subject["geoip"] }.nil?
     end

     sample("@type" => "syslog", '@message' => '<6>2015-08-17T10:02:18Z canopy-labs.example.com doppler[6375]: {"cf_app_id":"e3c4579a-d3bd-4857-9294-dc6348735848","cf_app_name":"logs","cf_org_id":"c59cb38f-f40a-42b4-ad6c-053413e4b3f3","cf_org_name":"cip-sys","cf_space_id":"637da72a-59ad-4773-987c-72f2d9a53fae","cf_space_name":"elk-for-pcf","event_type":"LogMessage","level":"info","message_type":"OUT","msg":"logs.sys.demo.labs.cf.canopy-cloud.com - [17/08/2015:10:02:17 +0000] \"POST /elasticsearch/_mget?timeout=0\u0026ignore_unavailable=true\u0026preference=1439805736876 HTTP/1.1\" 200 86 352 \"https://logs.sys.demo.labs.cf.canopy-cloud.com/\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:40.0) Gecko/20100101 Firefox/40.0\" 10.0.16.5:35928 x_forwarded_for:\"94.197.120.100\" vcap_request_id:555e9aab-f0bb-49f0-4539-ec257d917435 response_time:0.006633385 app_id:e3c4579a-d3bd-4857-9294-dc6348735848\n","origin":"router__0","source_instance":"0","source_type":"RTR","time":"2015-08-17T10:02:17Z","timestamp":1439805737627585338}') do
        #puts subject.to_hash.to_yaml

        insist { subject["@tags"].sort } == [ 'syslog_standard', 'firehose', "RTR" ].sort

        insist { subject["RTR"]["status"] } == 200
        insist { subject["RTR"]["request_bytes_received"] } == 86
        insist { subject["RTR"]["body_bytes_sent"] } == 352
     end

     describe "RTR logs get correct @level" do
         sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:22:43Z jumpbox.xxxxxxx.com doppler[6375]: {"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"OUT","msg":"cf-env-test.xxxxxxx.com - [17/03/2015:01:21:42 +0000] \"GET / HTTP/1.1\" 401 5087 \"-\" \"Mozilla/5.0\" 10.10.0.71:45298 x_forwarded_for:\"-\" vcap_request_id:c66716aa-fef1-482f-55c3-133be3ed8de7 response_time:0.003644458 app_id:ec2d33f6-fd1c-49a5-9a90-031454d1f1ac\n","source_instance":"0","source_type":"RTR","time":"2015-03-17T01:22:43Z"}') do
           #puts subject.to_hash.to_yaml
           insist { subject["@tags"].sort } == [ 'syslog_standard', 'firehose', "RTR" ].sort
           insist { subject['@level'] } == "WARN" 
         end
         sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:22:43Z jumpbox.xxxxxxx.com doppler[6375]: {"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"OUT","msg":"cf-env-test.xxxxxxx.com - [17/03/2015:01:21:42 +0000] \"GET / HTTP/1.1\" 503 5087 \"-\" \"Mozilla/5.0\" 10.10.0.71:45298 x_forwarded_for:\"-\" vcap_request_id:c66716aa-fef1-482f-55c3-133be3ed8de7 response_time:0.003644458 app_id:ec2d33f6-fd1c-49a5-9a90-031454d1f1ac\n","source_instance":"0","source_type":"RTR","time":"2015-03-17T01:22:43Z"}') do
           #puts subject.to_hash.to_yaml
           insist { subject["@tags"].sort } == [ 'syslog_standard', 'firehose', "RTR" ].sort
           insist { subject['@level'] } == "ERROR" 
         end
     end

     describe "CF v222 RTR log format" do
         sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:22:43Z jumpbox.xxxxxxx.com doppler[6375]: {"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"OUT","msg":"logs.system.pcf-1-6.stayup.io - [12/11/2015:08:06:38 +0000] \"POST /elasticsearch/_msearch?timeout=0&ignore_unavailable=true&preference=1447315596384 HTTP/1.1\" 200 773 21088 \"https://logs.system.pcf-1-6.stayup.io/app/kibana\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.80 Safari/537.36\" 10.0.0.196:7490 x_forwarded_for:\"188.29.165.38\" x_forwarded_proto:\"https\" vcap_request_id:d5e3f390-9cb7-4f2a-43bf-dc26478a23ef response_time:0.597601978 app_id:f5235df2-0b26-496d-a54d-defda2b9e01a\n","source_instance":"0","source_type":"RTR","time":"2015-03-17T01:22:43Z"}') do
           
           puts subject.to_hash.to_yaml
           
           insist { subject["@tags"].sort } == [ 'syslog_standard', 'firehose', "RTR" ].sort

           insist { subject["RTR"]["x_forwarded_for"] } == [ "188.29.165.38" ]
           insist { subject["RTR"]["x_forwarded_proto"] } == "https" 

         end
     end
     
   end

   describe "message_type=ERR" do
     sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:22:43Z jumpbox.xxxxxxx.com doppler[6375]: {"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"ERR","msg":"184.169.44.78, 192.168.16.3, 184.169.44.78, 10.10.0.71 - - [17/Mar/2015 01:21:42] \"GET / HTTP/1.1\" 200 5087 0.0022","source_instance":"0","source_type":"App","time":"2015-03-17T01:22:43Z"}') do

       insist { subject["@tags"] } == [ 'syslog_standard', 'firehose' ]
       insist { subject["@metadata"]["type"] } == "LogMessage"

       #timestamp should come from the inner RTR timestamp
       insist { subject["@timestamp"] } == Time.iso8601("2015-03-17T01:22:43Z")

       insist { subject["@level"] } == "INFO"
       insist { subject["@source"]["app"]["id"] } == "ec2d33f6-fd1c-49a5-9a90-031454d1f1ac"
       insist { subject["@source"]["message_type"] } == "ERR"
       insist { subject["@source"]["component"] } == "App"
       insist { subject["@source"]["instance"] } == 0

       insist { subject["@message"] } == '184.169.44.78, 192.168.16.3, 184.169.44.78, 10.10.0.71 - - [17/Mar/2015 01:21:42] "GET / HTTP/1.1" 200 5087 0.0022'

     end

     sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:22:40Z jumpbox.xxxxxxx.com doppler[6375]: {"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"ERR","msg":"W, [2015-03-17T01:21:39.739322 #31] WARN -- : attack prevented by Rack::Protection::IPSpoofing","source_instance":"0","source_type":"App","time":"2015-03-17T01:22:40Z"}') do

      # puts subject.to_hash.to_yaml

       insist { subject["@tags"] } == [ 'syslog_standard', 'firehose' ]
       insist { subject["@metadata"]["type"] } == "LogMessage"

       #timestamp should come from the inner RTR timestamp
       insist { subject["@timestamp"] } == Time.iso8601("2015-03-17T01:22:40Z")

       insist { subject["@level"] } == "INFO"
       insist { subject["@source"]["app"]["id"] } == "ec2d33f6-fd1c-49a5-9a90-031454d1f1ac"
       insist { subject["@source"]["message_type"] } == "ERR"
       insist { subject["@source"]["component"] } == "App"
       insist { subject["@source"]["instance"] } == 0

       insist { subject["@message"] } == 'W, [2015-03-17T01:21:39.739322 #31] WARN -- : attack prevented by Rack::Protection::IPSpoofing'

     end

   end

    describe "Decorate app logs with name, org and space" do
      sample("@type" => "syslog", "@message" => '<6>2015-03-17T01:22:43Z jumpbox.xxxxxxx.com doppler[6375]: {"cf_app_name":"myappname","cf_space_name":"myspacename","cf_org_name":"myorgname","cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"ERR","msg":"184.169.44.78, 192.168.16.3, 184.169.44.78, 10.10.0.71 - - [17/Mar/2015 01:21:42] \"GET / HTTP/1.1\" 200 5087 0.0022","source_instance":"0","source_type":"App","time":"2015-03-17T01:22:43Z"}') do
        #puts subject.to_hash.to_yaml

        insist { subject["@tags"] } == [ 'syslog_standard', 'firehose' ]
        insist { subject["@metadata"]["type"] } == "LogMessage"

        insist { subject["@source"]["app"]["id"] } == "ec2d33f6-fd1c-49a5-9a90-031454d1f1ac"
        insist { subject["@source"]["app"]["name"] } == "myappname"
        insist { subject["@source"]["space"]["name"] } == "myspacename"
        insist { subject["@source"]["org"]["name"] } == "myorgname"
      end

    end

    describe "Handle unicode newline character - \u2028" do
	sample("@type"=>"syslog", "@message" => "<6>2015-08-18T10:01:35Z 15875963-9c45-4544-a5e8-f34bcd84c8a2 doppler[4241]: {\"cf_app_id\":\"ced331e4-43d8-42ff-9a16-5126a7ae9d3a\",\"cf_app_name\":\"quotes\",\"cf_org_id\":\"1e91cfa1-c754-4759-ae80-ce172b89ffd2\",\"cf_org_name\":\"stayUp\",\"cf_space_id\":\"1aba7f55-79f3-464b-8e53-9348c9e48997\",\"cf_space_name\":\"development\",\"event_type\":\"LogMessage\",\"level\":\"info\",\"message_type\":\"OUT\",\"msg\":\"2015-08-18 10:01:35.834  WARN 33 --- [io-61013-exec-9] i.p.quotes.controller.QuoteController    : Handle Error: io.pivotal.quotes.exception.SymbolNotFoundException: Symbol not found: FOOBAR\\u2028\\tat io.pivotal.quotes.service.QuoteService.getQuote(QuoteService.java:52) ~[app/:na]\\u2028\\tat io.pivotal.quotes.controller.QuoteController.getQuote(QuoteController.java:58) ~[app/:na]\\u2028\\tat sun.reflect.GeneratedMethodAccessor38.invoke(Unknown Source) ~[na:na]\\u2028\\tat sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43) ~[na:1.8.0_51-]\\u2028\\tat org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run(TaskThread.java:61) [tomcat-embed-core-8.0.23.jar!/:8.0.23]\\u2028\\tat java.lang.Thread.run(Thread.java:745) [na:1.8.0_51-]\\u2028\",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"App\",\"time\":\"2015-08-18T10:01:35Z\",\"timestamp\":1439892095835415236}") do

        #puts subject.to_hash.to_yaml

        insist { subject["@tags"] } == [ 'syslog_standard', 'firehose' ]

        insist { subject["@message"] } == "2015-08-18 10:01:35.834  WARN 33 --- [io-61013-exec-9] i.p.quotes.controller.QuoteController    : Handle Error: io.pivotal.quotes.exception.SymbolNotFoundException: Symbol not found: FOOBAR\n\tat io.pivotal.quotes.service.QuoteService.getQuote(QuoteService.java:52) ~[app/:na]\n\tat io.pivotal.quotes.controller.QuoteController.getQuote(QuoteController.java:58) ~[app/:na]\n\tat sun.reflect.GeneratedMethodAccessor38.invoke(Unknown Source) ~[na:na]\n\tat sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43) ~[na:1.8.0_51-]\n\tat org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run(TaskThread.java:61) [tomcat-embed-core-8.0.23.jar!/:8.0.23]\n\tat java.lang.Thread.run(Thread.java:745) [na:1.8.0_51-]\n"
      end

    end
  end

end
