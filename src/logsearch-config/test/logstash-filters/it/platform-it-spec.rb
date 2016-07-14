# encoding: utf-8
require 'test/filter_test_helpers'

describe "Platform Integration Test" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("target/logstash-filters-default.conf")} # NOTE: we use already built config here
      }
    CONFIG
  end

  describe "when message is platform log" do

    context "(vcap)" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "vcap.consul-agent",
          "syslog_pri" => "14",
          "syslog_severity_code" => 3,
          "host" => "192.168.111.24:44577",
          "@message" => "[job=nfs_z1 index=0] {\"timestamp\":1467852972.554088,\"source\":\"NatsStreamForwarder\",\"log_level\":\"info\",\"message\":\"router.register\",\"data\":{\"nats_message\": \"{\\\"uris\\\":[\\\"redis-broker.64.78.234.207.xip.io\\\"],\\\"host\\\":\\\"192.168.111.201\\\",\\\"port\\\":80}\",\"reply_inbox\":\"_INBOX.7e93f2a1d5115844163cc930b5\"}}"
      ) do

        # no parsing errors
        it { expect(subject["@tags"]).not_to include "fail/cloudfoundry/platform/grok" }

        # fields
        it "should set common fields" do
          expect(subject["@input"]).to eq "relp"
          expect(subject["@shipper"]["priority"]).to eq "14"
          expect(subject["@shipper"]["name"]).to eq "vcap.consul-agent_relp"
          expect(subject["@source"]["host"]).to eq "192.168.111.24:44577"
          expect(subject["@source"]["name"]).to eq "nfs_z1/0"
          expect(subject["@source"]["instance"]).to eq 0

          expect(subject["@metadata"]["index"]).to eq "platform"
        end

        it "should override common fields" do
          expect(subject["@source"]["component"]).to eq "consul-agent"
          expect(subject["@type"]).to eq "vcap_cf"
          expect(subject["@tags"]).to eq ["cf", "vcap"]
        end

        it "should set mandatory fields" do
          expect(subject["@message"]).to eq "router.register"
          expect(subject["vcap"]["message"]).to be_nil
          expect(subject["@level"]).to eq "INFO"
          expect(subject["vcap"]["log_level"]).to be_nil
        end

        # vcap-specific fields
        it "should set [vcap] fields from JSON" do
          expect(subject["vcap"]).not_to be_nil
          expect(subject["vcap"]["timestamp"]).to eq 1467852972.554088
          expect(subject["vcap"]["source"]).to eq "NatsStreamForwarder"
          expect(subject["vcap"]["data"]["nats_message"]).to eq "{\"uris\":[\"redis-broker.64.78.234.207.xip.io\"],\"host\":\"192.168.111.201\",\"port\":80}"
          expect(subject["vcap"]["data"]["reply_inbox"]).to eq "_INBOX.7e93f2a1d5115844163cc930b5"
        end

      end
    end

    context "(haproxy)" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "haproxy",
          "syslog_pri" => "14",
          "syslog_severity_code" => 3,
          "host" => "192.168.111.24:44577",
          "@message" => "[job=ha_proxy_z1 index=0]  64.78.155.208:60677 [06/Jul/2016:13:59:57.770] https-in~ http-routers/node0 59841/0/0/157/60000 200 144206 reqC respC ---- 3/4/1/2/0 5/6 {reqHeaders} {respHeaders} \"GET /v2/apps?inline-relations-depth=2 HTTP/1.1\""
      ) do

        # no parsing errors
        it { expect(subject["@tags"]).not_to include "fail/cloudfoundry/platform/grok" }

        # fields
        it "should set common fields" do
          expect(subject["@input"]).to eq "relp"
          expect(subject["@shipper"]["priority"]).to eq "14"
          expect(subject["@shipper"]["name"]).to eq "haproxy_relp"
          expect(subject["@source"]["host"]).to eq "192.168.111.24:44577"
          expect(subject["@source"]["name"]).to eq "ha_proxy_z1/0"
          expect(subject["@source"]["instance"]).to eq 0

          expect(subject["@metadata"]["index"]).to eq "platform"
        end

        it "should override common fields" do
          expect(subject["@source"]["component"]).to eq "haproxy"
          expect(subject["@type"]).to eq "haproxy_cf"
          expect(subject["@tags"]).to eq ["cf", "haproxy"]
        end

        it "should set mandatory fields" do
          expect(subject["@message"]).to eq "GET /v2/apps?inline-relations-depth=2 HTTP/1.1"
          expect(subject["@level"]).to eq "INFO"
        end

        # haproxy-specific fields
        it "should set [haproxy] fields from grok" do
          expect(subject["haproxy"]["client_ip"]).to eq "64.78.155.208"
          expect(subject["haproxy"]["client_port"]).to eq "60677"
          expect(subject["haproxy"]["accept_date"]).to eq "06/Jul/2016:13:59:57.770"
          expect(subject["haproxy"]["frontend_name"]).to eq "https-in~"
          expect(subject["haproxy"]["backend_name"]).to eq "http-routers"
          expect(subject["haproxy"]["server_name"]).to eq "node0"
          expect(subject["haproxy"]["time_request"]).to eq "59841"
          expect(subject["haproxy"]["time_queue"]).to eq "0"
          expect(subject["haproxy"]["time_backend_connect"]).to eq "0"
          expect(subject["haproxy"]["time_backend_response"]).to eq "157"
          expect(subject["haproxy"]["time_duration"]).to eq "60000"
          expect(subject["haproxy"]["http_status_code"]).to eq 200
          expect(subject["haproxy"]["bytes_read"]).to eq "144206"
          expect(subject["haproxy"]["captured_request_cookie"]).to eq "reqC"
          expect(subject["haproxy"]["captured_response_cookie"]).to eq "respC"
          expect(subject["haproxy"]["termination_state"]).to eq "----"
          expect(subject["haproxy"]["actconn"]).to eq "3"
          expect(subject["haproxy"]["feconn"]).to eq "4"
          expect(subject["haproxy"]["beconn"]).to eq "1"
          expect(subject["haproxy"]["srvconn"]).to eq "2"
          expect(subject["haproxy"]["retries"]).to eq "0"
          expect(subject["haproxy"]["srv_queue"]).to eq "5"
          expect(subject["haproxy"]["backend_queue"]).to eq "6"
          expect(subject["haproxy"]["captured_request_headers"]).to eq "reqHeaders"
          expect(subject["haproxy"]["captured_response_headers"]).to eq "respHeaders"
          expect(subject["haproxy"]["http_request"]).to eq "GET /v2/apps?inline-relations-depth=2 HTTP/1.1"
          expect(subject["haproxy"]["http_request_verb"]).to eq "GET"
        end

      end
    end

    context "(uaa)" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "vcap.uaa",
          "syslog_pri" => "14",
          "syslog_severity_code" => 3,
          "host" => "192.168.111.24:44577",
          "@message" => "[job=uaa_z0 index=0]  [2016-07-05 04:02:18.245] uaa - 15178 [http-bio-8080-exec-14] ....  INFO --- Audit: ClientAuthenticationSuccess ('Client authentication success'): principal=cf, origin=[remoteAddress=64.78.155.208, clientId=cf], identityZoneId=[uaa]"
      ) do

        # no parsing errors
        it { expect(subject["@tags"]).not_to include "fail/cloudfoundry/platform/grok" }

        # fields
        it "should set common fields" do
          expect(subject["@input"]).to eq "relp"
          expect(subject["@shipper"]["priority"]).to eq "14"
          expect(subject["@shipper"]["name"]).to eq "vcap.uaa_relp"
          expect(subject["@source"]["host"]).to eq "192.168.111.24:44577"
          expect(subject["@source"]["name"]).to eq "uaa_z0/0"
          expect(subject["@source"]["instance"]).to eq 0

          expect(subject["@metadata"]["index"]).to eq "platform"
        end

        it "should override common fields" do
          expect(subject["@source"]["component"]).to eq "uaa"
          expect(subject["@type"]).to eq "uaa_cf"
          expect(subject["@tags"]).to eq ["cf", "uaa"]
        end

        it "should set mandatory fields" do
          expect(subject["@message"]).to eq "ClientAuthenticationSuccess ('Client authentication success')"
          expect(subject["@level"]).to eq "INFO"
        end

        # uaa-specific fields
        it "should set geoip for remoteAddress" do
          expect(subject["geoip"]).not_to be_nil
          expect(subject["geoip"]["ip"]).to eq "64.78.155.208"
        end

        it "should set [uaa] fields" do
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

      end
    end

  end

  describe "when message is unparsed" do

    when_parsing_log(
        "@type" => "relp",
        "syslog_program" => "some-program", # not a platform log
        "syslog_pri" => "14",
        "syslog_severity_code" => 3,
        "host" => "192.168.111.24:44577",
        "@message" => "Some message" # not a platform log
    ) do

      # parsing error
      it { expect(subject["@tags"]).to include "fail/cloudfoundry/platform/grok" }

      # fields
      it "should set common fields" do
        expect(subject["@input"]).to eq "relp"
        expect(subject["@shipper"]["priority"]).to eq "14"
        expect(subject["@shipper"]["name"]).to eq "some-program_relp"
        expect(subject["@source"]["host"]).to eq "192.168.111.24:44577"
        expect(subject["@source"]["name"]).to be_nil
        expect(subject["@source"]["instance"]).to be_nil
        expect(subject["@source"]["component"]).to eq "some-program"
        expect(subject["@type"]).to eq "relp"

        expect(subject["@metadata"]["index"]).to eq "unparsed"
      end

      it "should set mandatory fields" do
        expect(subject["@message"]).to eq "Some message"
        expect(subject["@level"]).to eq "ERROR"
      end

    end

  end

end
