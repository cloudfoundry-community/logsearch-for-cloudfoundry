# encoding: utf-8
require 'test/logstash-filters/filter_test_helpers'
require 'test/logstash-filters/it_platform_helper' # platform it util

describe "Platform IT" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("target/logstash-filters-default.conf")} # NOTE: we use already built config here
      }
    CONFIG
  end

  # init event (dummy)
  platform_event_dummy = {"@type" => "relp",
                     "syslog_pri" => "14",
                     "syslog_severity_code" => 3, # ERROR
                     "host" => "192.168.111.24",
                     "syslog_program" => "Dummy program",
                     "@message" => "Dummy message"}

  describe "when CF and format is" do

    context "vcap (plain text)" do

      message_payload = MessagePayloadBuilder.new
          .job("nfs_z1")
          .message_text('Some vcap plain text message') # plain text message
          .build()
      sample_event = platform_event_dummy.clone
      sample_event["@message"] = construct_platform_message(message_payload)
      sample_event["syslog_program"] = "vcap.consul-agent" # vcap

      when_parsing_log(sample_event) do

        verify_platform_cf_fields("vcap.consul-agent_relp", "consul-agent", "nfs_z1",
          "vcap", ["platform", "cf", "vcap"], "Some vcap plain text message", "ERROR")

        it { expect(subject["consul_agent"]).to be_nil } # no json fields

      end
    end

    context "vcap (json)" do

      message_payload = MessagePayloadBuilder.new
                            .job("nfs_z1")
                            .message_text('{"timestamp":1467852972.554088,"source":"NatsStreamForwarder", ' +
                                              '"log_level":"info","message":"router.register", ' +
                                              '"data":{"nats_message": "{\"uris\":[\"redis-broker.64.78.234.207.xip.io\"],\"host\":\"192.168.111.201\",\"port\":80}",' +
                                              '"reply_inbox":"_INBOX.7e93f2a1d5115844163cc930b5"}}')
                            .build() # JSON message
      sample_event = platform_event_dummy.clone
      sample_event["@message"] = construct_platform_message(message_payload)
      sample_event["syslog_program"] = "vcap.consul-agent" # vcap

      when_parsing_log(sample_event) do

        verify_platform_cf_fields("vcap.consul-agent_relp", "consul-agent", "nfs_z1",
                      "vcap", ["platform", "cf", "vcap"], "router.register", "INFO")

        # json fields
        it "sets fields from JSON" do
          expect(subject["consul_agent"]).not_to be_nil
          expect(subject["consul_agent"]["timestamp"]).to eq 1467852972.554088
          expect(subject["consul_agent"]["source"]).to eq "NatsStreamForwarder"
          expect(subject["consul_agent"]["data"]["nats_message"]).to eq "{\"uris\":[\"redis-broker.64.78.234.207.xip.io\"],\"host\":\"192.168.111.201\",\"port\":80}"
          expect(subject["consul_agent"]["data"]["reply_inbox"]).to eq "_INBOX.7e93f2a1d5115844163cc930b5"
        end

      end
    end

    context "haproxy" do
      message_payload = MessagePayloadBuilder.new
                            .job("ha_proxy_z1")
                            .message_text('64.78.155.208:60677 [06/Jul/2016:13:59:57.770] https-in~ http-routers/node0 59841/0/0/157/60000 200 144206 reqC respC ---- 3/4/1/2/0 5/6 {reqHeaders} {respHeaders} "GET /v2/apps?inline-relations-depth=2 HTTP/1.1"')
                            .build()
      sample_event = platform_event_dummy.clone
      sample_event["@message"] = construct_platform_message(message_payload)
      sample_event["syslog_program"] = "haproxy" # haproxy

      when_parsing_log(sample_event) do

        verify_platform_cf_fields("haproxy_relp", "haproxy", "ha_proxy_z1",
                      "haproxy", ["platform", "cf", "haproxy"], "GET /v2/apps?inline-relations-depth=2 HTTP/1.1", "INFO")

        # haproxy fields
        it "sets [haproxy] fields from grok" do
          expect(subject["haproxy"]["client_ip"]).to eq "64.78.155.208"
          expect(subject["haproxy"]["client_port"]).to eq 60677
          expect(subject["haproxy"]["accept_date"]).to eq "06/Jul/2016:13:59:57.770"
          expect(subject["haproxy"]["frontend_name"]).to eq "https-in~"
          expect(subject["haproxy"]["backend_name"]).to eq "http-routers"
          expect(subject["haproxy"]["server_name"]).to eq "node0"
          expect(subject["haproxy"]["time_request"]).to eq 59841
          expect(subject["haproxy"]["time_queue"]).to eq 0
          expect(subject["haproxy"]["time_backend_connect"]).to eq 0
          expect(subject["haproxy"]["time_backend_response"]).to eq 157
          expect(subject["haproxy"]["time_duration"]).to eq 60000
          expect(subject["haproxy"]["http_status_code"]).to eq 200
          expect(subject["haproxy"]["bytes_read"]).to eq 144206
          expect(subject["haproxy"]["captured_request_cookie"]).to eq "reqC"
          expect(subject["haproxy"]["captured_response_cookie"]).to eq "respC"
          expect(subject["haproxy"]["termination_state"]).to eq "----"
          expect(subject["haproxy"]["actconn"]).to eq 3
          expect(subject["haproxy"]["feconn"]).to eq 4
          expect(subject["haproxy"]["beconn"]).to eq 1
          expect(subject["haproxy"]["srvconn"]).to eq 2
          expect(subject["haproxy"]["retries"]).to eq 0
          expect(subject["haproxy"]["srv_queue"]).to eq 5
          expect(subject["haproxy"]["backend_queue"]).to eq 6
          expect(subject["haproxy"]["captured_request_headers"]).to eq "reqHeaders"
          expect(subject["haproxy"]["captured_response_headers"]).to eq "respHeaders"
          expect(subject["haproxy"]["http_request"]).to eq "GET /v2/apps?inline-relations-depth=2 HTTP/1.1"
          expect(subject["haproxy"]["http_request_verb"]).to eq "GET"
        end

      end
    end

    context "uaa" do
      message_payload = MessagePayloadBuilder.new
                            .job("uaa_z0")
                            .message_text('[2016-07-05 04:02:18.245] uaa - 15178 [http-bio-8080-exec-14] ....  INFO --- Audit: ClientAuthenticationSuccess (\'Client authentication success\'): principal=cf, origin=[remoteAddress=64.78.155.208, clientId=cf], identityZoneId=[uaa]')
                            .build()
      sample_event = platform_event_dummy.clone
      sample_event["@message"] = construct_platform_message(message_payload)
      sample_event["syslog_program"] = "vcap.uaa" # uaa

      when_parsing_log(sample_event) do

        verify_platform_cf_fields("vcap.uaa_relp", "uaa", "uaa_z0",
                      "uaa", ["platform", "cf", "uaa"],
                      "ClientAuthenticationSuccess ('Client authentication success')", "INFO")

        # uaa fields
        it "sets [uaa] fields" do
          expect(subject["uaa"]["pid"]).to eq 15178
          expect(subject["uaa"]["thread_name"]).to eq "http-bio-8080-exec-14"
          expect(subject["uaa"]["timestamp"]).to eq "2016-07-05 04:02:18.245"
          expect(subject["uaa"]["type"]).to eq "ClientAuthenticationSuccess"
          expect(subject["uaa"]["remote_address"]).to eq "64.78.155.208"
          expect(subject["uaa"]["data"]).to eq "Client authentication success"
          expect(subject["uaa"]["principal"]).to eq "cf"
          expect(subject["uaa"]["origin"]).to eq ["remoteAddress=64.78.155.208", "clientId=cf"]
          expect(subject["uaa"]["identity_zone_id"]).to eq "uaa"
        end

        it "sets geoip for remoteAddress" do
          expect(subject["geoip"]).not_to be_nil
          expect(subject["geoip"]["ip"]).to eq "64.78.155.208"
        end

      end
    end

  end

  describe "when not CF" do

    sample_event = platform_event_dummy.clone
    sample_event["@message"] = "Some message" # not CF

    when_parsing_log(sample_event) do

      verify_platform_fields("Dummy program_relp", "Dummy program",
                    "relp", ["platform", "fail/cloudfoundry/platform/grok"], "Some message", "ERROR")

      it { expect(subject["@source"]["type"]).to eq "system" }

    end
  end

end

