# encoding: utf-8
require 'test/filter_test_helpers'

describe "Firehose logs parsing rules" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/firehose.conf")}
      }
    CONFIG
  end

  describe "Parse Cloud Foundry doppler messages" do
    describe "invalid json" do
      when_parsing_log(
        "@type" => "syslog",
        "syslog_program" => "doppler",
        "@message" => '{"invalid }'
      ) do

        it "adds failed tag" do
          expect(subject["tags"]).to include 'fail/cloudfoundry/firehose/jsonparsefailure_of_syslog_message'
        end
      end
    end

    describe "source_type=DEA" do
      when_parsing_log(
        "@type" => "syslog",
        "syslog_program" => "doppler",
        "@message" => '{"cf_app_id":"b732c465-0536-4014-b922-165eb38857b2","level":"info","message_type":"OUT","msg":"Stopped app instance (index 0) with guid b732c465-0536-4014-b922-165eb38857b2","source_instance":"7","source_type":"DEA","time":"2015-03-17T01:24:23Z"}'
      ) do

        it "adds firehose tag" do
          expect(subject["tags"]).to include "firehose"
        end

        it "sets @type" do
          expect(subject['@type']).to eq "app"
        end

        it "sets @timestamp" do
          expect(subject["@timestamp"]).to eq Time.iso8601("2015-03-17T01:24:23.000Z")
        end

        it "sets @level" do
          expect(subject["@level"]).to eq "INFO"
        end

        it "sets @source.app.id" do
          expect(subject["@source"]["app"]["id"]).to eq "b732c465-0536-4014-b922-165eb38857b2"
        end

        it "sets @source.message_type" do
          expect(subject["@source"]["message_type"]).to eq "OUT"
        end

        it "sets @source.component" do
          expect(subject["@source"]["component"]).to eq "DEA"
        end

        it "sets @source.instance" do
          expect(subject["@source"]["instance"]).to eq 7
        end

        it "sets @source.name" do
          expect(subject["@source"]["name"]).to eq "DEA/7"
        end

        it "sets @message" do
          expect(subject["@message"]).to eq "Stopped app instance (index 0) with guid b732c465-0536-4014-b922-165eb38857b2"
        end
      end
    end #describe "source_type=DEA"

    describe "source_type=RTR" do
      when_parsing_log(
        "@type" => "syslog",
        "syslog_program" => "doppler",
        "@message" => '{"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"OUT","msg":"cf-env-test.xxxxxxx.com - [17/03/2015:01:21:42 +0000] \"GET / HTTP/1.1\" 200 5087 \"-\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36\" 10.10.0.71:45298 x_forwarded_for:\"184.169.44.78, 192.168.16.3, 184.169.44.78, 10.10.0.71\" vcap_request_id:c66716aa-fef1-482f-55c3-133be3ed8de7 response_time:0.3644458 app_id:ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","source_instance":"0","source_type":"RTR","time":"2015-03-17T01:22:43Z"}'
      ) do
        #puts subject.to_hash.to_yaml

        it "adds firehose tag" do
          expect(subject["tags"]).to include "firehose"
        end

        it "sets @type" do
          expect(subject['@type']).to eq "app"
        end

        it "sets @timestamp" do
          expect(subject["@timestamp"]).to eq Time.iso8601("2015-03-17T01:21:42.000Z")
        end

        it "sets @level" do
          expect(subject["@level"]).to eq "INFO"
        end

        it "sets @source.app.id" do
          expect(subject["@source"]["app"]["id"]).to eq "ec2d33f6-fd1c-49a5-9a90-031454d1f1ac"
        end

        it "sets @source.message_type" do
          expect(subject["@source"]["message_type"]).to eq "OUT"
        end

        it "sets @source.component" do
          expect(subject["@source"]["component"]).to eq "RTR"
        end

        it "sets @source.instance" do
          expect(subject["@source"]["instance"]).to eq 0
        end

        it "sets @source.name" do
          expect(subject["@source"]["name"]).to eq "RTR/0"
        end

        it "sets @message" do
          expect(subject["@message"]).to eq 'cf-env-test.xxxxxxx.com - [17/03/2015:01:21:42 +0000] "GET / HTTP/1.1" 200 5087 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36" 10.10.0.71:45298 x_forwarded_for:"184.169.44.78, 192.168.16.3, 184.169.44.78, 10.10.0.71" vcap_request_id:c66716aa-fef1-482f-55c3-133be3ed8de7 response_time:0.3644458 app_id:ec2d33f6-fd1c-49a5-9a90-031454d1f1ac'
        end

        #timestamp should come from the inner RTR timestamp
        it "extracts the router log details" do
          expect(subject["RTR"]["verb"]).to eq "GET"
          expect(subject["RTR"]["path"]).to eq "/"
          expect(subject["RTR"]["http_spec"]).to eq "HTTP/1.1"
          expect(subject["RTR"]["status"]).to eq 200
          expect(subject["RTR"]["body_bytes_sent"]).to eq 5087
          expect(subject["RTR"]["referer"]).to eq "-"
          expect(subject["RTR"]["http_user_agent"]).to eq "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36"

          expect(subject["RTR"]["remote_addr"]).to eq "184.169.44.78"
          expect(subject["RTR"]["x_forwarded_for"]).to eq [ "184.169.44.78", "192.168.16.3", "184.169.44.78", "10.10.0.71" ]
          expect(subject["geoip"]["location"]).to eq [ -118.8935, 34.14439999999999 ]

          expect(subject["RTR"]["vcap_request_id"]).to eq "c66716aa-fef1-482f-55c3-133be3ed8de7"
          expect(subject["RTR"]["response_time_ms"]).to eq 364
        end
      end

      context "when x_forwarded_for is empty" do
        when_parsing_log(
          "@type" => "syslog",
          "syslog_program" => "doppler",
          "@message" => '{"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"OUT","msg":"cf-env-test.xxxxxxx.com - [17/03/2015:01:21:42 +0000] \"GET / HTTP/1.1\" 200 5087 \"-\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36\" 10.10.0.71:45298 x_forwarded_for:\"-\" vcap_request_id:c66716aa-fef1-482f-55c3-133be3ed8de7 response_time:0.003644458 app_id:ec2d33f6-fd1c-49a5-9a90-031454d1f1ac\n","source_instance":"0","source_type":"RTR","time":"2015-03-17T01:22:43Z"}'
        ) do
          #puts subject.to_hash.to_yaml

          it "does not do geoip lookup" do
            expect(subject["geoip"]).to be_nil
          end
        end
      end

      context "when request_bytes_received is present" do
        when_parsing_log(
          "@type" => "syslog",
          "syslog_program" => "doppler",
          '@message' => '{"cf_app_id":"e3c4579a-d3bd-4857-9294-dc6348735848","cf_app_name":"logs","cf_org_id":"c59cb38f-f40a-42b4-ad6c-053413e4b3f3","cf_org_name":"cip-sys","cf_space_id":"637da72a-59ad-4773-987c-72f2d9a53fae","cf_space_name":"elk-for-pcf","event_type":"LogMessage","level":"info","message_type":"OUT","msg":"logs.sys.demo.labs.cf.canopy-cloud.com - [17/08/2015:10:02:17 +0000] \"POST /elasticsearch/_mget?timeout=0\u0026ignore_unavailable=true\u0026preference=1439805736876 HTTP/1.1\" 200 86 352 \"https://logs.sys.demo.labs.cf.canopy-cloud.com/\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:40.0) Gecko/20100101 Firefox/40.0\" 10.0.16.5:35928 x_forwarded_for:\"94.197.120.100\" vcap_request_id:555e9aab-f0bb-49f0-4539-ec257d917435 response_time:0.006633385 app_id:e3c4579a-d3bd-4857-9294-dc6348735848\n","origin":"router__0","source_instance":"0","source_type":"RTR","time":"2015-08-17T10:02:17Z","timestamp":1439805737627585338}'
        ) do
          #puts subject.to_hash.to_yaml

          it "extracts request_bytes_received" do
            expect(subject["RTR"]["request_bytes_received"]).to eq 86
          end
        end
      end

      context "when HTTP status indicates an error" do
        when_parsing_log(
          "@type" => "syslog",
          "syslog_program" => "doppler",
          "@message" => '{"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"OUT","msg":"cf-env-test.xxxxxxx.com - [17/03/2015:01:21:42 +0000] \"GET / HTTP/1.1\" 401 5087 \"-\" \"Mozilla/5.0\" 10.10.0.71:45298 x_forwarded_for:\"-\" vcap_request_id:c66716aa-fef1-482f-55c3-133be3ed8de7 response_time:0.003644458 app_id:ec2d33f6-fd1c-49a5-9a90-031454d1f1ac\n","source_instance":"0","source_type":"RTR","time":"2015-03-17T01:22:43Z"}'
        ) do

          it "sets @level" do
            expect(subject['@level']).to eq "ERROR"
          end
        end

        when_parsing_log(
          "@type" => "syslog",
          "syslog_program" => "doppler",
          "@message" => '{"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"OUT","msg":"cf-env-test.xxxxxxx.com - [17/03/2015:01:21:42 +0000] \"GET / HTTP/1.1\" 503 5087 \"-\" \"Mozilla/5.0\" 10.10.0.71:45298 x_forwarded_for:\"-\" vcap_request_id:c66716aa-fef1-482f-55c3-133be3ed8de7 response_time:0.003644458 app_id:ec2d33f6-fd1c-49a5-9a90-031454d1f1ac\n","source_instance":"0","source_type":"RTR","time":"2015-03-17T01:22:43Z"}'
        ) do

          it "sets @level" do
            expect(subject['@level']).to eq "ERROR"
          end
        end
      end

      context "when log is in CF v222+ format" do
        when_parsing_log(
          "@type" => "syslog",
          "syslog_program" => "doppler",
          "@message" => '{"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"OUT","msg":"logs.system.pcf-1-6.stayup.io - [12/11/2015:08:06:38 +0000] \"POST /elasticsearch/_msearch?timeout=0&ignore_unavailable=true&preference=1447315596384 HTTP/1.1\" 200 773 21088 \"https://logs.system.pcf-1-6.stayup.io/app/kibana\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.80 Safari/537.36\" 10.0.0.196:7490 x_forwarded_for:\"188.29.165.38\" x_forwarded_proto:\"https\" vcap_request_id:d5e3f390-9cb7-4f2a-43bf-dc26478a23ef response_time:0.597601978 app_id:f5235df2-0b26-496d-a54d-defda2b9e01a\n","source_instance":"0","source_type":"RTR","time":"2015-03-17T01:22:43Z"}'
        ) do


          it "extracts router log details" do
            expect(subject["RTR"]["x_forwarded_for"]).to eq [ "188.29.165.38" ]
            expect(subject["RTR"]["x_forwarded_proto"]).to eq "https"
          end
        end
      end
    end # RTR logs

    describe "message_type=ERR" do
      when_parsing_log(
        "@type" => "syslog",
        "syslog_program" => "doppler",
        "@message" => '{"cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"ERR","msg":"184.169.44.78, 192.168.16.3, 184.169.44.78, 10.10.0.71 - - [17/Mar/2015 01:21:42] \"GET / HTTP/1.1\" 200 5087 0.0022","source_instance":"0","source_type":"App","time":"2015-03-17T01:22:43Z"}'
      ) do

        it "adds firehose tag" do
          expect(subject["tags"]).to include "firehose"
        end

        it "sets @type" do
          expect(subject['@type']).to eq "app"
        end

        it "sets @timestamp" do
          expect(subject["@timestamp"]).to eq Time.iso8601("2015-03-17T01:22:43.000Z")
        end

        it "sets @level" do
          expect(subject["@level"]).to eq "INFO"
        end

        it "sets @source.app.id" do
          expect(subject["@source"]["app"]["id"]).to eq "ec2d33f6-fd1c-49a5-9a90-031454d1f1ac"
        end

        it "sets @source.message_type" do
          expect(subject["@source"]["message_type"]).to eq "ERR"
        end

        it "sets @source.component" do
          expect(subject["@source"]["component"]).to eq "App"
        end

        it "sets @source.instance" do
          expect(subject["@source"]["instance"]).to eq 0
        end

        it "sets @message" do
         expect(subject["@message"]).to eq '184.169.44.78, 192.168.16.3, 184.169.44.78, 10.10.0.71 - - [17/Mar/2015 01:21:42] "GET / HTTP/1.1" 200 5087 0.0022'
        end
      end

      when_parsing_log(
        "@type" => "syslog",
        "syslog_program" => "doppler",
        "@message" => '{"cf_app_name":"myappname","cf_space_name":"myspacename","cf_org_name":"myorgname","cf_app_id":"ec2d33f6-fd1c-49a5-9a90-031454d1f1ac","level":"info","message_type":"ERR","msg":"184.169.44.78, 192.168.16.3, 184.169.44.78, 10.10.0.71 - - [17/Mar/2015 01:21:42] \"GET / HTTP/1.1\" 200 5087 0.0022","source_instance":"0","source_type":"App","time":"2015-03-17T01:22:43Z"}'
      ) do

        it "extracts app specific details" do
          expect(subject["@source"]["app"]["id"]).to eq "ec2d33f6-fd1c-49a5-9a90-031454d1f1ac"
          expect(subject["@source"]["app"]["name"]).to eq "myappname"
          expect(subject["@source"]["space"]["name"]).to eq "myspacename"
          expect(subject["@source"]["org"]["name"]).to eq "myorgname"
        end
      end
    end # type ERR

    describe "ContainerMetric log parsing" do
      when_parsing_log(
        "@type"=>"syslog",
        "syslog_program" => "doppler",
        "@message" => '{"cf_app_id":"9120a7f2-8a2d-4b86-bb1a-6d5a08c5f7c4","cf_app_name":"apps-manager-blue","cf_org_id":"0a7e5b2e-acb2-4d1c-ae1b-fc77b9abafc2","cf_org_name":"system","cf_space_id":"9698aaeb-1b0c-4a5b-9a31-739c752d990e","cf_space_name":"apps-manager","cpu_percentage":0.02542316766514131,"disk_bytes":286732288,"event_type":"ContainerMetric","instance_index":0,"level":"info","memory_bytes":111882240,"msg":"","origin":"rep","time":"2015-11-11T17:09:08Z"}'
      ) do

        it "adds firehose tag" do
          expect(subject["tags"]).to include "firehose"
        end

        it "sets @source.name" do
          expect(subject["@source"]["name"]).to eq "METRIC/0"
        end

        it "extracts container metrics" do
          expect(subject["container"]["cpu_percentage"]).to eq 0.02542316766514131
          expect(subject["container"]["disk_bytes"]).to eq 286732288
          expect(subject["container"]["memory_bytes"]).to eq 111882240
        end
      end
    end
  end
end
