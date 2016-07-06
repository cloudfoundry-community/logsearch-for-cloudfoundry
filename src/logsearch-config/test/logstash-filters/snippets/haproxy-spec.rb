# encoding: utf-8
require 'test/filter_test_helpers'

describe "Haproxy spec" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/haproxy.conf")}
      }
    CONFIG
  end

  describe "Http log format" do
    when_parsing_log(
      "@type" => "syslog_cf",
      "syslog_program" => "haproxy",
      "@message" => "64.78.155.208:60677 [06/Jul/2016:13:59:57.770] https-in~ http-routers/node0 59841/0/0/157/60000 200 144206 reqC respC ---- 3/4/1/2/0 5/6 {reqHeaders} {respHeaders} \"GET /v2/apps?inline-relations-depth=2 HTTP/1.1\""
    ) do

      # Check that @message is parsed with no errors
      it "does not include grok fail tag" do
        expect(subject["tags"]).not_to include "fail/cloudfoundry/haproxy/grok"
      end

      # Check fields

      # grok fields
      it "sets [haproxy] fields from grok" do
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

      # @message & @level
      it "sets @message from grok" do
        expect(subject["@message"]).to eq "GET /v2/apps?inline-relations-depth=2 HTTP/1.1"
      end

      it "sets @level from grok" do
        expect(subject["@level"]).to eq "INFO"
      end

      # basic fields
      it "sets [@source][component]" do
        expect(subject["@source"]["component"]).to eq "haproxy"
      end

      it "sets @type" do
        expect(subject["@type"]).to eq "haproxy_cf"
      end

      it "sets 'uaa' tag" do
        expect(subject["tags"]).to include "haproxy"
      end

    end
  end

  describe "Http log format - <BADREQ>" do
    when_parsing_log(
        "@type" => "syslog_cf",
        "syslog_program" => "haproxy",
        "@message" => "64.78.155.208:60677 [06/Jul/2016:13:59:57.770] https-in~ http-routers/node0 59841/0/0/157/60000 200 144206 reqC respC ---- 3/4/1/2/0 5/6 {reqHeaders} {respHeaders} \"<BADREQ>\""
    ) do

      # grok fields
      it "sets [haproxy][request] from grok" do
        expect(subject["haproxy"]["http_request"]).to eq "<BADREQ>"
        expect(subject["haproxy"]["http_request_verb"]).to be_nil
      end

    end
  end

  describe "Http log format - ERROR level" do
    when_parsing_log(
        "@type" => "syslog_cf",
        "syslog_program" => "haproxy",
        "@message" => "64.78.155.208:60677 [06/Jul/2016:13:59:57.770] https-in~ http-routers/node0 59841/0/0/157/60000 400 144206 reqC respC ---- 3/4/1/2/0 5/6 {reqHeaders} {respHeaders} \"GET /v2/apps?inline-relations-depth=2 HTTP/1.1\""
    ) do

      # Check @level is set based on [haproxy][http_status_code]
      it "sets @level to ERROR" do
        expect(subject["@level"]).to eq "ERROR"
      end

    end
  end

  describe "Error log format" do
    when_parsing_log(
        "@type" => "syslog_cf",
        "syslog_program" => "haproxy",
        "@message" => "216.218.206.68:36743 [06/Jul/2016:07:16:34.605] https-in/1: SSL handshake failure"
    ) do

      # Check that @message is parsed with no errors
      it "does not include grok fail tag" do
        expect(subject["tags"]).not_to include "fail/cloudfoundry/haproxy/grok"
      end

      # Check fields

      # grok fields
      it "sets [haproxy] fields from grok" do
        expect(subject["haproxy"]["client_ip"]).to eq "216.218.206.68"
        expect(subject["haproxy"]["client_port"]).to eq "36743"
        expect(subject["haproxy"]["accept_date"]).to eq "06/Jul/2016:07:16:34.605"
        expect(subject["haproxy"]["frontend_name"]).to eq "https-in"
        expect(subject["haproxy"]["bind_name"]).to eq "1"
      end

      # @message & @level
      it "sets @message from grok" do
        expect(subject["@message"]).to eq "SSL handshake failure"
      end

      it "sets @level from grok" do
        expect(subject["@level"]).to be_nil
      end

      # basic fields
      it "sets [@source][component]" do
        expect(subject["@source"]["component"]).to eq "haproxy"
      end

      it "sets @type" do
        expect(subject["@type"]).to eq "haproxy_cf"
      end

      it "sets 'uaa' tag" do
        expect(subject["tags"]).to include "haproxy"
      end

    end
  end

end
