# encoding: utf-8
require 'spec_helper'

describe "platform-haproxy.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/platform-haproxy.conf")}
      }
    CONFIG
  end

  describe "#if" do

    describe "passed" do
      when_parsing_log(
          "@source" => {"component" => "haproxy"}, # good value
          "@message" => "Some message"
      ) do

        # tag set => 'if' succeeded
        it { expect(parsed_results.get("tags")).to include "haproxy" }

      end
    end

    describe "failed" do
      when_parsing_log(
          "@source" => {"component" => "some value"}, # bad value
          "@message" => "Some message"
      ) do

        # no tags set => 'if' failed
        it { expect(parsed_results.get("tags")).to be_nil }

        it { expect(parsed_results.get("@type")).to be_nil } # keeps unchanged
        it { expect(parsed_results.get("@source")["component"]).to eq "some value" } # keeps unchanged
        it { expect(parsed_results.get("@message")).to eq "Some message" } # keeps unchanged

      end
    end

  end

  # -- general case
  describe "#fields when message is" do
    context "Http format" do
      when_parsing_log(
          "@source" => {"component" => "haproxy"},
          # http format
          "@message" => "64.78.155.208:60677 [06/Jul/2016:13:59:57.770] https-in~ http-routers/node0 59841/0/0/157/60000 200 144206 reqC respC ---- 3/4/1/2/0 5/6 {reqHeaders} {respHeaders} \"GET /v2/apps?inline-relations-depth=2 HTTP/1.1\""
      ) do

        it { expect(parsed_results.get("tags")).to eq ["haproxy"] } # haproxy tag, no fail tag

        it { expect(parsed_results.get("@type")).to eq "haproxy" }
        it { expect(parsed_results.get("@source")["component"]).to eq "haproxy" } # keeps unchanged

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

        it { expect(parsed_results.get("@message")).to eq "GET /v2/apps?inline-relations-depth=2 HTTP/1.1" }
        it { expect(parsed_results.get("@level")).to eq "INFO" }

      end
    end

    context "Http format (<BADREQ>)" do
      when_parsing_log(
          "@source" => {"component" => "haproxy"},
          # http format
          "@message" => "64.78.155.208:60677 [06/Jul/2016:13:59:57.770] https-in~ http-routers/node0 59841/0/0/157/60000 " +
              "200 144206 reqC respC ---- 3/4/1/2/0 5/6 {reqHeaders} {respHeaders} \"<BADREQ>\"" # <BADREQ>
      ) do

        it "sets [haproxy][request] to <BADREQ>" do
          expect(parsed_results.get("haproxy")["http_request"]).to eq "<BADREQ>"
          expect(parsed_results.get("haproxy")["http_request_verb"]).to be_nil
        end

      end
    end

    context "Http format (ERROR level)" do
      when_parsing_log(
          "@source" => {"component" => "haproxy"},
          "@message" => "64.78.155.208:60677 [06/Jul/2016:13:59:57.770] https-in~ http-routers/node0 59841/0/0/157/60000 " +
              "400" + # http status = 400 => ERROR level
              " 144206 reqC respC ---- 3/4/1/2/0 5/6 {reqHeaders} {respHeaders} \"GET /v2/apps?inline-relations-depth=2 HTTP/1.1\""
      ) do

        # @level is set based on [haproxy][http_status_code]
        it { expect(parsed_results.get("@level")).to eq "ERROR" }

      end
    end

    context "Error log format" do
      when_parsing_log(
          "@source" => {"component" => "haproxy"},
          # error log
          "@message" => "216.218.206.68:36743 [06/Jul/2016:07:16:34.605] https-in/1: SSL handshake failure"
      ) do

        it { expect(parsed_results.get("tags")).to eq ["haproxy"] } # haproxy tag, no fail tag

        it { expect(parsed_results.get("@type")).to eq "haproxy" }
        it { expect(parsed_results.get("@source")["component"]).to eq "haproxy" } # keeps unchanged

        it "sets [haproxy] fields from grok" do
          expect(parsed_results.get("haproxy")["client_ip"]).to eq "216.218.206.68"
          expect(parsed_results.get("haproxy")["client_port"]).to eq 36743
          expect(parsed_results.get("haproxy")["accept_date"]).to eq "06/Jul/2016:07:16:34.605"
          expect(parsed_results.get("haproxy")["frontend_name"]).to eq "https-in"
          expect(parsed_results.get("haproxy")["bind_name"]).to eq "1"
        end

        it { expect(parsed_results.get("@message")).to eq "SSL handshake failure" }

      end
    end

    context "Unknown format" do
      when_parsing_log(
          "@source" => {"component" => "haproxy"},
          # error log
          "@message" => "Some message"
      ) do

        # parsing error
        it { expect(parsed_results.get("tags")).to eq ["haproxy", "fail/cloudfoundry/platform-haproxy/grok"] } # no fail tag

        it { expect(parsed_results.get("@type")).to eq "haproxy" }
        it { expect(parsed_results.get("@source")["component"]).to eq "haproxy" } # keeps unchanged
        it { expect(parsed_results.get("@message")).to eq "Some message" } # keeps unchanged
        it { expect(parsed_results.get("haproxy")).to be_nil }

      end
    end

  end

end
