# encoding: utf-8
require 'spec_helper'

describe "App IT" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("target/logstash-filters-default.conf")} # NOTE: we use already built config here
      }
    CONFIG

  end

  describe "#fields when event is" do

    describe "LogMessage (APP)" do
      # NOTE: below tests include two checks - one for Diego, another for Dea

      context "(unknown msg format)" do

        verify_parsing_logmessage_app_CF_versions(
                "warn", "Some text msg", # unknown msg format
                "WARN", "Some text msg") do

          # verify format-specific fields
                  it { expect(parsed_results.get("tags")).to include "unknown_msg_format" }

        end
      end

      context "(JSON)" do

        verify_parsing_logmessage_app_CF_versions(
                "warn", "{\\\"timestamp\\\":\\\"2016-07-15 13:20:16.954\\\",\\\"level\\\":\\\"ERROR\\\"," +
                "\\\"thread\\\":\\\"main\\\",\\\"logger\\\":\\\"com.abc.LogGenerator\\\"," +
                "\\\"message\\\":\\\"Some json msg\\\"}", # JSON msg
                "ERROR", "Some json msg") do

          # verify format-specific fields
                  it { expect(parsed_results.get("tags")).not_to include "unknown_msg_format" }

          it "sets [app] fields from JSON msg" do
            expect(parsed_results.get("app")["timestamp"]).to eq "2016-07-15 13:20:16.954"
            expect(parsed_results.get("app")["thread"]).to eq "main"
            expect(parsed_results.get("app")["logger"]).to eq "com.abc.LogGenerator"
          end

        end
      end

      context "([CONTAINER] log)" do

        verify_parsing_logmessage_app_CF_versions(
                # [CONTAINER] log
                "warn", "[CONTAINER] org.apache.catalina.startup.Catalina    INFO    Server startup in 9775 ms",
                "INFO", "Server startup in 9775 ms") do

          # verify format-specific fields
                  it { expect(parsed_results.get("tags")).not_to include "unknown_msg_format" }
                  it { expect(parsed_results.get("app")["logger"]).to eq "[CONTAINER] org.apache.catalina.startup.Catalina" }

        end
      end

      context "(Logback status log)" do

        verify_parsing_logmessage_app_CF_versions(
                # Logback status log
                "warn", "16:41:17,033 |-DEBUG in ch.qos.logback.classic.joran.action.RootLoggerAction - Setting level of ROOT logger to WARN",
                "DEBUG", "Setting level of ROOT logger to WARN") do

          # verify format-specific fields
                  it { expect(parsed_results.get("tags")).not_to include "unknown_msg_format" }
                  it { expect(parsed_results.get("app")["logger"]).to eq "ch.qos.logback.classic.joran.action.RootLoggerAction" }

        end
      end

    end

    describe "LogMessage (RTR)" do

      sample_event = $app_event_dummy.clone
      sample_event["@message"] = construct_event("LogMessage", true,
                                                 {"source_type" => "RTR", # RTR
                                                  "source_instance" => "99",
                                                  "message_type" => "OUT",
                                                  "timestamp" => 1471387745714800488,
                                                  "level" => "debug",
                                                  # RTR message
                                                  "msg" => 'parser.64.78.234.207.xip.io - [2017-03-16T13:28:25.166+0000] \"GET / HTTP/1.1\" ' +
                                                           '200 0 1677 \"-\" \"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.67 Safari/537.36\" ' +
                                                           '\"10.2.9.104:60079\" \"10.2.32.71:61010\" x_forwarded_for:\"82.209.244.50, 192.168.111.21\" x_forwarded_proto:\"https\" ' +
                                                           'vcap_request_id:\"f322dd76-aacf-422e-49fb-c73bc46ce45b\" response_time:0.001602684 app_id:\"27c02dec-80ce-4af6-94c5-2b51848edae9\" app_index:\"1\"\\\n'})

      when_parsing_log(sample_event) do

        verify_app_general_fields("app-admin-demo", "LogMessage", "RTR",
                                  # RTR message
                                  '200 GET / (1.602 ms)', "INFO")

        verify_app_cf_fields(99)

        # verify event-specific fields
        it { expect(parsed_results.get("tags")).to include("logmessage", "logmessage-rtr") }
        it { expect(parsed_results.get("tags")).not_to include("fail/cloudfoundry/app-rtr/grok") }

        it { expect(parsed_results.get("logmessage")["message_type"]).to eq "OUT" }

        it "sets [rtr] fields" do
          expect(parsed_results.get("rtr")["hostname"]).to eq "parser.64.78.234.207.xip.io"
          expect(parsed_results.get("rtr")["timestamp"]).to eq "2017-03-16T13:28:25.166+0000"
          expect(parsed_results.get("rtr_time")).to be_nil
          expect(parsed_results.get("rtr")["verb"]).to eq "GET"
          expect(parsed_results.get("rtr")["path"]).to eq "/"
          expect(parsed_results.get("rtr")["http_spec"]).to eq "HTTP/1.1"
          expect(parsed_results.get("rtr")["status"]).to eq 200
          expect(parsed_results.get("rtr")["request_bytes_received"]).to eq 0
          expect(parsed_results.get("rtr")["body_bytes_sent"]).to eq 1677
          expect(parsed_results.get("rtr")["referer"]).to eq "-"
          expect(parsed_results.get("rtr")["http_user_agent"]).to eq "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.67 Safari/537.36"
          expect(parsed_results.get("rtr")["x_forwarded_for"]).to eq ["82.209.244.50", "192.168.111.21"]
          expect(parsed_results.get("rtr")["x_forwarded_proto"]).to eq "https"
          expect(parsed_results.get("rtr")["vcap_request_id"]).to eq "f322dd76-aacf-422e-49fb-c73bc46ce45b"
          expect(parsed_results.get("rtr")["src"]["host"]).to eq "10.2.9.104"
          expect(parsed_results.get("rtr")["src"]["port"]).to eq 60079
          expect(parsed_results.get("rtr")["dst"]["host"]).to eq "10.2.32.71"
          expect(parsed_results.get("rtr")["dst"]["port"]).to eq 61010
          expect(parsed_results.get("rtr")["app"]["id"]).to eq "27c02dec-80ce-4af6-94c5-2b51848edae9"
          expect(parsed_results.get("rtr")["app"]["index"]).to eq 1
          # calculated values
          expect(parsed_results.get("rtr")["remote_addr"]).to eq "82.209.244.50"
          expect(parsed_results.get("rtr")["response_time_ms"]).to eq 1.602
        end

        it "sets geoip for [rtr][remote_addr]" do
          expect(parsed_results.get("geoip")).not_to be_nil
          expect(parsed_results.get("geoip")["ip"]).to eq "82.209.244.50"
        end

      end
    end

    describe "LogMessage (other)" do

      sample_event = $app_event_dummy.clone
      sample_event["@message"] = construct_event("LogMessage", true,
                                                 {"source_type" => "CELL", # neither APP, nor RTR
                                                  "source_instance" => "99",
                                                  "message_type" => "OUT",
                                                  "timestamp" => 1471387745714800488,
                                                  "level" => "debug",
                                                  "msg" => "Container became healthy"})

      when_parsing_log(sample_event) do

        verify_app_general_fields("app-admin-demo", "LogMessage", "CELL",
                                  "Container became healthy", "DEBUG")

        verify_app_cf_fields(99)

        # verify event-specific fields
        it { expect(parsed_results.get("tags")).to include "logmessage" }
        it { expect(parsed_results.get("logmessage")["message_type"]).to eq "OUT" }

      end
    end

    describe "CounterEvent" do

      sample_event = $app_event_dummy.clone
      sample_event["@message"] = construct_event( "CounterEvent", false,
                                                  {"name" => "MessageAggregator.uncategorizedEvents",
                                                   "delta" => 15,
                                                   "total" => 29043,
                                                   "level" => "info",
                                                   "msg" => ""})

      when_parsing_log(sample_event) do

        verify_app_general_fields("app", "CounterEvent", "COUNT",
                                  "MessageAggregator.uncategorizedEvents (delta=15, total=29043)", "INFO")

        # verify event-specific fields
        it { expect(parsed_results.get("tags")).to include "counterevent" }

        it "sets [counterevent] fields" do
          expect(parsed_results.get("counterevent")["name"]).to eq "MessageAggregator.uncategorizedEvents"
          expect(parsed_results.get("counterevent")["delta"]).to eq 15
          expect(parsed_results.get("counterevent")["total"]).to eq 29043
        end

      end
    end

    describe "ContainerMetric" do

      sample_event = $app_event_dummy.clone
      sample_event["@message"] = construct_event( "ContainerMetric", false,
                                                  {"cpu_percentage" => 99,
                                                   "disk_bytes" => 134524928,
                                                   "memory_bytes" => 142368768,
                                                   "level" => "info",
                                                   "msg" => ""})

      when_parsing_log(sample_event) do

        verify_app_general_fields("app", "ContainerMetric", "CONTAINER",
                                  "cpu=99, memory=142368768, disk=134524928", "INFO")

        # verify event-specific fields
        it { expect(parsed_results.get("tags")).to include "containermetric" }

        it "sets [containermetric] fields" do
          expect(parsed_results.get("containermetric")["cpu_percentage"]).to eq 99
          expect(parsed_results.get("containermetric")["disk_bytes"]).to eq 134524928
          expect(parsed_results.get("containermetric")["memory_bytes"]).to eq 142368768
        end

      end
    end

    describe "ValueMetric" do

      sample_event = $app_event_dummy.clone
      sample_event["@message"] = construct_event( "ValueMetric", false,
                                                  {"name" => "numGoRoutines",
                                                   "value" => 58,
                                                   "unit" => "count",
                                                   "level" => "info",
                                                   "msg" => ""})

      when_parsing_log(sample_event) do

        verify_app_general_fields("app", "ValueMetric", "METRIC",
                                  "numGoRoutines = 58 (count)", "INFO")

        # verify event-specific fields
        it { expect(parsed_results.get("tags")).to include "valuemetric" }

        it "sets [valuemetric] fields" do
          expect(parsed_results.get("valuemetric")["name"]).to eq "numGoRoutines"
          expect(parsed_results.get("valuemetric")["value"]).to eq 58
          expect(parsed_results.get("valuemetric")["unit"]).to eq "count"
        end

      end
    end

    describe "Error" do

      sample_event = $app_event_dummy.clone
      sample_event["@message"] = construct_event( "Error", false,
                                                  {"source" => "uaa",
                                                   "code" => 4,
                                                   "level" => "info",
                                                   "msg" => "Error message"})

      when_parsing_log(sample_event) do

        verify_app_general_fields("app", "Error", "ERR",
                                  "Error message", "INFO")

        # verify event-specific fields
        it { expect(parsed_results.get("tags")).to include "error" }

        it "sets [error] fields" do
          expect(parsed_results.get("error")["source"]).to eq "uaa"
          expect(parsed_results.get("error")["code"]).to eq 4
        end

      end
    end

    describe "HttpStartStop" do

      sample_event = $app_event_dummy.clone
      sample_event["@message"] = construct_event( "HttpStartStop", false,
                                                  {"content_length" => 38,
                                                   "duration_ms" => 6,
                                                   "instance_id" => "1b1fc66f-9aca-47b1-796c-d9632b23f1b3",
                                                   "instance_index" => 2,
                                                   "method" => "GET",
                                                   "peer_type" => "Server",
                                                   "remote_addr" => "192.168.111.11:42801",
                                                   "request_id" => "aa694b2c-6e26-4688-4b88-4574aa4e95a5",
                                                   "start_timestamp" => 1471387748611165439,
                                                   "status_code" => 200,
                                                   "stop_timestamp" => 1471387748618073991,
                                                   "uri" => "http://192.168.111.11/internal/v3/bulk/task_states",
                                                   "user_agent" => "Go-http-client/1.1",
                                                   "level" => "info",
                                                   "msg" => ""})


      when_parsing_log(sample_event) do

        verify_app_general_fields("app", "HttpStartStop", "HTTP",
                                  "200 GET http://192.168.111.11/internal/v3/bulk/task_states (6 ms)", "INFO")

        # verify event-specific fields
        it { expect(parsed_results.get("tags")).to include "http" }

        it "sets [httpstartstop] fields" do
          expect(parsed_results.get("httpstartstop")["content_length"]).to eq 38
          expect(parsed_results.get("httpstartstop")["duration_ms"]).to eq 6
          expect(parsed_results.get("httpstartstop")["instance_id"]).to eq "1b1fc66f-9aca-47b1-796c-d9632b23f1b3"
          expect(parsed_results.get("httpstartstop")["instance_index"]).to eq 2
          expect(parsed_results.get("httpstartstop")["method"]).to eq "GET"
          expect(parsed_results.get("httpstartstop")["peer_type"]).to eq "Server"
          expect(parsed_results.get("httpstartstop")["remote_addr"]).to eq "192.168.111.11:42801"
          expect(parsed_results.get("httpstartstop")["request_id"]).to eq "aa694b2c-6e26-4688-4b88-4574aa4e95a5"
          expect(parsed_results.get("httpstartstop")["status_code"]).to eq 200
          expect(parsed_results.get("httpstartstop")["stop_timestamp"]).to eq 1471387748618073991
          expect(parsed_results.get("httpstartstop")["uri"]).to eq "http://192.168.111.11/internal/v3/bulk/task_states"
          expect(parsed_results.get("httpstartstop")["user_agent"]).to eq "Go-http-client/1.1"
        end

      end

    end

  end


  # -- Special cases
  describe "drops useless LogMessage-APP event" do

    context "(drop)" do

      sample_event = $app_event_dummy.clone
      sample_event["@message"] = construct_event( "LogMessage", true,
                                  {"source_type" => "APP", "source_instance" => "99",
                                   "message_type" => "OUT", "timestamp" => 1471387745714800488,
                                   "level" => "info", "msg" => ""}) # LogMEssage-App with empty msg => useless

      when_parsing_log(sample_event) do
        it { expect(parsed_results).to be_nil } # drop event
      end
    end

    context "(keep)" do

      sample_event = $app_event_dummy.clone
      sample_event["@message"] = construct_event( "SomeOtherEvent", true,
                                {"timestamp" => 1471387745714800488, "level" => "info",
                                 "msg" => ""}) # some event with empty msg => still useful

      when_parsing_log(sample_event) do
        it { expect(parsed_results).not_to be_nil } # keeps event
      end
    end

  end

end
