# encoding: utf-8
require 'spec_helper'

describe "platform-cloud_controller_ng.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/platform-cloud_controller_ng.conf")}
      }
    CONFIG
  end

  describe "#if" do

    describe "passed" do
      when_parsing_log(
          "@source" => {"component" => "cloud_controller_ng"}, # good value
          "@message" => "Some message"
      ) do

        # tag set => 'if' succeeded
        it { expect(parsed_results.get("tags")).to include "cloud_controller_ng" }

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
    context "request format" do
      when_parsing_log(
          "@source" => {"component" => "cloud_controller_ng"},
          # cloud_controller_ng event
          "@message" => '10.10.128.8 - [17/Aug/2019:11:59:22 +0000] "GET /healthz HTTP/1.1" 200 248 "-" "ccng_monit_http_healthcheck" 10.10.128.8 vcap_request_id:f7c00c99-052c-41ec-9c7d-89c2826dcc60 response_time:0.008'
      ) do

        it { expect(parsed_results.get("tags")).to eq ["cloud_controller_ng"] } # cloud_controller_ng tag, no fail tag

        it { expect(parsed_results.get("@type")).to eq "cloud_controller_ng" }
        it { expect(parsed_results.get("@source")["component"]).to eq "cloud_controller_ng" } # keeps unchanged

        it "sets [cloud_controller_ng] fields from grok" do
          expect(parsed_results.get("Request_Method")).to eq "GET"
          expect(parsed_results.get("Request_Host")).to eq "10.10.128.8"
          expect(parsed_results.get("Request_URL")).to eq "/healthz"
          expect(parsed_results.get("Request_Protocol")).to eq "HTTP/1.1"
          expect(parsed_results.get("Status_Code")).to eq 200
          expect(parsed_results.get("Bytes_Received")).to eq 248
          expect(parsed_results.get("Referer")).to eq "-"
          expect(parsed_results.get("User_Agent")).to eq "ccng_monit_http_healthcheck"
          expect(parsed_results.get("Backend_Address")).to eq "10.10.128.8"
          expect(parsed_results.get("X_Vcap_Request_ID")).to eq "f7c00c99-052c-41ec-9c7d-89c2826dcc60"
          expect(parsed_results.get("Response_Time")).to eq "0.008"
        end

      end
    end

    context "Unknown format" do
      when_parsing_log(
          "@source" => {"component" => "cloud_controller_ng"},
          "@message" => "Some message"
      ) do

        # parsing error
        it { expect(parsed_results.get("tags")).to eq ["cloud_controller_ng", "fail/cloudfoundry/platform-cloud_controller_ng/grok"] } # no fail tag

        it { expect(parsed_results.get("@type")).to eq "cloud_controller_ng" }
        it { expect(parsed_results.get("@source")["component"]).to eq "cloud_controller_ng" } # keeps unchanged
        it { expect(parsed_results.get("@message")).to eq "Some message" } # keeps unchanged

      end
    end

  end

end
