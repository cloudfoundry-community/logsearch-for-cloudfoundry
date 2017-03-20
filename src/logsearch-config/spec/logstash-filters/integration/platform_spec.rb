# encoding: utf-8
require 'spec_helper'

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
                     "syslog_pri" => 14,
                     "syslog_severity_code" => 3, # ERROR
                     "host" => "192.168.111.24",
                     "syslog_program" => "Dummy program",
                     "@message" => "Dummy message"}

  describe "when CF (metron agent) and format is" do

    context "vcap (plain text)" do

      message_payload = MessagePayloadBuilder.new
          .job("nfs_z1")
          .message_text('Some vcap plain text message') # plain text message
          .build()
      sample_event = platform_event_dummy.clone
      sample_event["@message"] = construct_cf_message__metronagent_format(message_payload)
      sample_event["syslog_program"] = "vcap.consul-agent" # vcap

      when_parsing_log(sample_event) do

        verify_platform_cf_fields__metronagent_format("vcap.consul-agent_relp", "consul-agent", "nfs_z1",
          "vcap", ["platform", "cf", "vcap"], "Some vcap plain text message", "ERROR")

        it { expect(parsed_results.get("consul_agent")).to be_nil } # no json fields

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
      sample_event["@message"] = construct_cf_message__metronagent_format(message_payload)
      sample_event["syslog_program"] = "vcap.consul-agent" # vcap

      when_parsing_log(sample_event) do

        verify_platform_cf_fields__metronagent_format("vcap.consul-agent_relp", "consul-agent", "nfs_z1",
                      "vcap", ["platform", "cf", "vcap"], "router.register", "INFO")

        # json fields
        it "sets fields from JSON" do
          expect(parsed_results.get("consul_agent")).not_to be_nil
          expect(parsed_results.get("consul_agent")["timestamp"].to_f).to eq 1467852972.554088
          expect(parsed_results.get("consul_agent")["source"]).to eq "NatsStreamForwarder"
          expect(parsed_results.get("consul_agent")["data"]["nats_message"]).to eq "{\"uris\":[\"redis-broker.64.78.234.207.xip.io\"],\"host\":\"192.168.111.201\",\"port\":80}"
          expect(parsed_results.get("consul_agent")["data"]["reply_inbox"]).to eq "_INBOX.7e93f2a1d5115844163cc930b5"
        end

      end
    end

    context "haproxy" do
      message_payload = MessagePayloadBuilder.new
                            .job("ha_proxy_z1")
                            .message_text('64.78.155.208:60677 [06/Jul/2016:13:59:57.770] https-in~ http-routers/node0 59841/0/0/157/60000 200 144206 reqC respC ---- 3/4/1/2/0 5/6 {reqHeaders} {respHeaders} "GET /v2/apps?inline-relations-depth=2 HTTP/1.1"')
                            .build()
      sample_event = platform_event_dummy.clone
      sample_event["@message"] = construct_cf_message__metronagent_format(message_payload)
      sample_event["syslog_program"] = "haproxy" # haproxy

      when_parsing_log(sample_event) do

        verify_platform_cf_fields__metronagent_format("haproxy_relp", "haproxy", "ha_proxy_z1",
                      "haproxy", ["platform", "cf", "haproxy"], "GET /v2/apps?inline-relations-depth=2 HTTP/1.1", "INFO")

        # haproxy fields
        it "sets [haproxy] fields from grok" do
          expect(parsed_results.get("haproxy")["client_ip"]).to eq "64.78.155.208"
          expect(parsed_results.get("haproxy")["client_port"]).to eq 60677
          expect(parsed_results.get("haproxy")["accept_date"]).to eq "06/Jul/2016:13:59:57.770"
          expect(parsed_results.get("haproxy")["frontend_name"]).to eq "https-in~"
          expect(parsed_results.get("haproxy")["backend_name"]).to eq "http-routers"
          expect(parsed_results.get("haproxy")["server_name"]).to eq "node0"
          expect(parsed_results.get("haproxy")["time_request"]).to eq 59841
          expect(parsed_results.get("haproxy")["time_queue"]).to eq 0
          expect(parsed_results.get("haproxy")["time_backend_connect"]).to eq 0
          expect(parsed_results.get("haproxy")["time_backend_response"]).to eq 157
          expect(parsed_results.get("haproxy")["time_duration"]).to eq 60000
          expect(parsed_results.get("haproxy")["http_status_code"]).to eq 200
          expect(parsed_results.get("haproxy")["bytes_read"]).to eq 144206
          expect(parsed_results.get("haproxy")["captured_request_cookie"]).to eq "reqC"
          expect(parsed_results.get("haproxy")["captured_response_cookie"]).to eq "respC"
          expect(parsed_results.get("haproxy")["termination_state"]).to eq "----"
          expect(parsed_results.get("haproxy")["actconn"]).to eq 3
          expect(parsed_results.get("haproxy")["feconn"]).to eq 4
          expect(parsed_results.get("haproxy")["beconn"]).to eq 1
          expect(parsed_results.get("haproxy")["srvconn"]).to eq 2
          expect(parsed_results.get("haproxy")["retries"]).to eq 0
          expect(parsed_results.get("haproxy")["srv_queue"]).to eq 5
          expect(parsed_results.get("haproxy")["backend_queue"]).to eq 6
          expect(parsed_results.get("haproxy")["captured_request_headers"]).to eq "reqHeaders"
          expect(parsed_results.get("haproxy")["captured_response_headers"]).to eq "respHeaders"
          expect(parsed_results.get("haproxy")["http_request"]).to eq "GET /v2/apps?inline-relations-depth=2 HTTP/1.1"
          expect(parsed_results.get("haproxy")["http_request_verb"]).to eq "GET"
        end

      end
    end

    context "uaa" do
      message_payload = MessagePayloadBuilder.new
                            .job("uaa_z0")
                            .message_text('[2016-07-05 04:02:18.245] uaa - 15178 [http-bio-8080-exec-14] ....  DEBUG --- FilterChainProxy: /healthz has an empty filter list')
                            .build()
      sample_event = platform_event_dummy.clone
      sample_event["@message"] = construct_cf_message__metronagent_format(message_payload)
      sample_event["syslog_program"] = "vcap.uaa" # uaa

      when_parsing_log(sample_event) do

        verify_platform_cf_fields__metronagent_format("vcap.uaa_relp", "uaa", "uaa_z0",
                      "uaa", ["platform", "cf", "uaa"],
                      "/healthz has an empty filter list", "DEBUG")

        it "sets [uaa] fields" do
          expect(parsed_results.get("uaa")["timestamp"]).to eq "2016-07-05 04:02:18.245"
          expect(parsed_results.get("uaa")["thread"]).to eq "http-bio-8080-exec-14"
          expect(parsed_results.get("uaa")["pid"]).to eq 15178
          expect(parsed_results.get("uaa")["log_category"]).to eq "FilterChainProxy"
        end

      end
    end

    context "uaa (Audit)" do
      message_payload = MessagePayloadBuilder.new
                            .job("uaa_z0")
                            .message_text('[2016-07-05 04:02:18.245] uaa - 15178 [http-bio-8080-exec-14] ....  INFO --- Audit: ClientAuthenticationSuccess (\'Client authentication success\'): principal=cf, origin=[remoteAddress=64.78.155.208, clientId=cf], identityZoneId=[uaa]')
                            .build()
      sample_event = platform_event_dummy.clone
      sample_event["@message"] = construct_cf_message__metronagent_format(message_payload)
      sample_event["syslog_program"] = "vcap.uaa" # uaa

      when_parsing_log(sample_event) do

        verify_platform_cf_fields__metronagent_format("vcap.uaa_relp", "uaa", "uaa_z0",
                                  "uaa-audit", ["platform", "cf", "uaa", "audit"],
                                  "ClientAuthenticationSuccess ('Client authentication success')", "INFO")

        it "sets [uaa] fields" do
          expect(parsed_results.get("uaa")["timestamp"]).to eq "2016-07-05 04:02:18.245"
          expect(parsed_results.get("uaa")["thread"]).to eq "http-bio-8080-exec-14"
          expect(parsed_results.get("uaa")["pid"]).to eq 15178
          expect(parsed_results.get("uaa")["log_category"]).to eq "Audit"
        end

        it "sets [uaa][audit] fields" do
          expect(parsed_results.get("uaa")["audit"]["type"]).to eq "ClientAuthenticationSuccess"
          expect(parsed_results.get("uaa")["audit"]["data"]).to eq "Client authentication success"
          expect(parsed_results.get("uaa")["audit"]["principal"]).to eq "cf"
          expect(parsed_results.get("uaa")["audit"]["origin"]).to eq ["remoteAddress=64.78.155.208", "clientId=cf"]
          expect(parsed_results.get("uaa")["audit"]["identity_zone_id"]).to eq "uaa"
          expect(parsed_results.get("uaa")["audit"]["remote_address"]).to eq "64.78.155.208"
        end

        it "sets geoip for remoteAddress" do
          expect(parsed_results.get("geoip")).not_to be_nil
          expect(parsed_results.get("geoip")["ip"]).to eq "64.78.155.208"
        end

      end
    end

  end

  describe "when CF (syslog release) and format is" do

    context "vcap (plain text)" do

      message_payload = MessagePayloadBuilder.new
                            .deployment("cf_full")
                            .job("nfs_z1")
                            .message_text('Some vcap plain text message') # plain text message
                            .build()
      sample_event = platform_event_dummy.clone
      sample_event["@message"] = construct_cf_message__syslogrelease_format(message_payload)
      sample_event["syslog_program"] = "vcap.consul-agent" # vcap

      when_parsing_log(sample_event) do

        verify_platform_cf_fields__syslogrelease_format("vcap.consul-agent_relp", "cf_full", "consul-agent", "nfs_z1",
                                  "vcap", ["platform", "cf", "vcap"], "Some vcap plain text message", "ERROR")

        it { expect(parsed_results.get("consul_agent")).to be_nil } # no json fields

      end
    end

    context "vcap (json)" do

      message_payload = MessagePayloadBuilder.new
                            .deployment("cf_full")
                            .job("nfs_z1")
                            .message_text('{"timestamp":1467852972.554088,"source":"NatsStreamForwarder", ' +
                                              '"log_level":"info","message":"router.register", ' +
                                              '"data":{"nats_message": "{\"uris\":[\"redis-broker.64.78.234.207.xip.io\"],\"host\":\"192.168.111.201\",\"port\":80}",' +
                                              '"reply_inbox":"_INBOX.7e93f2a1d5115844163cc930b5"}}')
                            .build() # JSON message
      sample_event = platform_event_dummy.clone
      sample_event["@message"] = construct_cf_message__syslogrelease_format(message_payload)
      sample_event["syslog_program"] = "vcap.consul-agent" # vcap

      when_parsing_log(sample_event) do

        verify_platform_cf_fields__syslogrelease_format("vcap.consul-agent_relp", "cf_full", "consul-agent", "nfs_z1",
                                  "vcap", ["platform", "cf", "vcap"], "router.register", "INFO")

        # json fields
        it "sets fields from JSON" do
          expect(parsed_results.get("consul_agent")).not_to be_nil
          expect(parsed_results.get("consul_agent")["timestamp"].to_f).to eq 1467852972.554088
          expect(parsed_results.get("consul_agent")["source"]).to eq "NatsStreamForwarder"
          expect(parsed_results.get("consul_agent")["data"]["nats_message"]).to eq "{\"uris\":[\"redis-broker.64.78.234.207.xip.io\"],\"host\":\"192.168.111.201\",\"port\":80}"
          expect(parsed_results.get("consul_agent")["data"]["reply_inbox"]).to eq "_INBOX.7e93f2a1d5115844163cc930b5"
        end

      end
    end

    context "haproxy" do
      message_payload = MessagePayloadBuilder.new
                            .deployment("cf_full")
                            .job("ha_proxy_z1")
                            .message_text('64.78.155.208:60677 [06/Jul/2016:13:59:57.770] https-in~ http-routers/node0 59841/0/0/157/60000 200 144206 reqC respC ---- 3/4/1/2/0 5/6 {reqHeaders} {respHeaders} "GET /v2/apps?inline-relations-depth=2 HTTP/1.1"')
                            .build()
      sample_event = platform_event_dummy.clone
      sample_event["@message"] = construct_cf_message__syslogrelease_format(message_payload)
      sample_event["syslog_program"] = "haproxy" # haproxy

      when_parsing_log(sample_event) do

        verify_platform_cf_fields__syslogrelease_format("haproxy_relp", "cf_full", "haproxy", "ha_proxy_z1",
                                  "haproxy", ["platform", "cf", "haproxy"], "GET /v2/apps?inline-relations-depth=2 HTTP/1.1", "INFO")

        # haproxy fields
        it "sets [haproxy] fields from grok" do
          expect(parsed_results.get("haproxy")["client_ip"]).to eq "64.78.155.208"
          expect(parsed_results.get("haproxy")["client_port"]).to eq 60677
          expect(parsed_results.get("haproxy")["accept_date"]).to eq "06/Jul/2016:13:59:57.770"
          expect(parsed_results.get("haproxy")["frontend_name"]).to eq "https-in~"
          expect(parsed_results.get("haproxy")["backend_name"]).to eq "http-routers"
          expect(parsed_results.get("haproxy")["server_name"]).to eq "node0"
          expect(parsed_results.get("haproxy")["time_request"]).to eq 59841
          expect(parsed_results.get("haproxy")["time_queue"]).to eq 0
          expect(parsed_results.get("haproxy")["time_backend_connect"]).to eq 0
          expect(parsed_results.get("haproxy")["time_backend_response"]).to eq 157
          expect(parsed_results.get("haproxy")["time_duration"]).to eq 60000
          expect(parsed_results.get("haproxy")["http_status_code"]).to eq 200
          expect(parsed_results.get("haproxy")["bytes_read"]).to eq 144206
          expect(parsed_results.get("haproxy")["captured_request_cookie"]).to eq "reqC"
          expect(parsed_results.get("haproxy")["captured_response_cookie"]).to eq "respC"
          expect(parsed_results.get("haproxy")["termination_state"]).to eq "----"
          expect(parsed_results.get("haproxy")["actconn"]).to eq 3
          expect(parsed_results.get("haproxy")["feconn"]).to eq 4
          expect(parsed_results.get("haproxy")["beconn"]).to eq 1
          expect(parsed_results.get("haproxy")["srvconn"]).to eq 2
          expect(parsed_results.get("haproxy")["retries"]).to eq 0
          expect(parsed_results.get("haproxy")["srv_queue"]).to eq 5
          expect(parsed_results.get("haproxy")["backend_queue"]).to eq 6
          expect(parsed_results.get("haproxy")["captured_request_headers"]).to eq "reqHeaders"
          expect(parsed_results.get("haproxy")["captured_response_headers"]).to eq "respHeaders"
          expect(parsed_results.get("haproxy")["http_request"]).to eq "GET /v2/apps?inline-relations-depth=2 HTTP/1.1"
          expect(parsed_results.get("haproxy")["http_request_verb"]).to eq "GET"
        end

      end
    end

    context "uaa" do
      message_payload = MessagePayloadBuilder.new
                            .deployment("cf_full")
                            .job("uaa_z0")
                            .message_text('[2016-07-05 04:02:18.245] uaa - 15178 [http-bio-8080-exec-14] ....  DEBUG --- FilterChainProxy: /healthz has an empty filter list')
                            .build()
      sample_event = platform_event_dummy.clone
      sample_event["@message"] = construct_cf_message__syslogrelease_format(message_payload)
      sample_event["syslog_program"] = "vcap.uaa" # uaa

      when_parsing_log(sample_event) do

        verify_platform_cf_fields__syslogrelease_format("vcap.uaa_relp", "cf_full", "uaa", "uaa_z0",
                                  "uaa", ["platform", "cf", "uaa"],
                                  "/healthz has an empty filter list", "DEBUG")

        it "sets [uaa] fields" do
          expect(parsed_results.get("uaa")["timestamp"]).to eq "2016-07-05 04:02:18.245"
          expect(parsed_results.get("uaa")["thread"]).to eq "http-bio-8080-exec-14"
          expect(parsed_results.get("uaa")["pid"]).to eq 15178
          expect(parsed_results.get("uaa")["log_category"]).to eq "FilterChainProxy"
        end

      end
    end

    context "uaa (Audit)" do
      message_payload = MessagePayloadBuilder.new
                            .deployment("cf_full")
                            .job("uaa_z0")
                            .message_text('[2016-07-05 04:02:18.245] uaa - 15178 [http-bio-8080-exec-14] ....  INFO --- Audit: ClientAuthenticationSuccess (\'Client authentication success\'): principal=cf, origin=[remoteAddress=64.78.155.208, clientId=cf], identityZoneId=[uaa]')
                            .build()
      sample_event = platform_event_dummy.clone
      sample_event["@message"] = construct_cf_message__syslogrelease_format(message_payload)
      sample_event["syslog_program"] = "vcap.uaa" # uaa

      when_parsing_log(sample_event) do

        verify_platform_cf_fields__syslogrelease_format("vcap.uaa_relp", "cf_full", "uaa", "uaa_z0",
                                  "uaa-audit", ["platform", "cf", "uaa", "audit"],
                                  "ClientAuthenticationSuccess ('Client authentication success')", "INFO")

        it "sets [uaa] fields" do
          expect(parsed_results.get("uaa")["timestamp"]).to eq "2016-07-05 04:02:18.245"
          expect(parsed_results.get("uaa")["thread"]).to eq "http-bio-8080-exec-14"
          expect(parsed_results.get("uaa")["pid"]).to eq 15178
          expect(parsed_results.get("uaa")["log_category"]).to eq "Audit"
        end

        it "sets [uaa][audit] fields" do
          expect(parsed_results.get("uaa")["audit"]["type"]).to eq "ClientAuthenticationSuccess"
          expect(parsed_results.get("uaa")["audit"]["data"]).to eq "Client authentication success"
          expect(parsed_results.get("uaa")["audit"]["principal"]).to eq "cf"
          expect(parsed_results.get("uaa")["audit"]["origin"]).to eq ["remoteAddress=64.78.155.208", "clientId=cf"]
          expect(parsed_results.get("uaa")["audit"]["identity_zone_id"]).to eq "uaa"
          expect(parsed_results.get("uaa")["audit"]["remote_address"]).to eq "64.78.155.208"
        end

        it "sets geoip for remoteAddress" do
          expect(parsed_results.get("geoip")).not_to be_nil
          expect(parsed_results.get("geoip")["ip"]).to eq "64.78.155.208"
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

      it { expect(parsed_results.get("@source")["type"]).to eq "system" }

    end
  end

end

