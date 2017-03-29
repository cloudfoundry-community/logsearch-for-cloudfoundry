# encoding: utf-8
require 'spec_helper'

describe "platform-vcap.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/platform-vcap.conf")}
      }
    CONFIG
  end

  describe "#if" do

    describe "passed" do
      when_parsing_log(
          "@source" => {"component" => "vcap.some_component"}, # good value
          "@message" => "Some message"
      ) do

        # tag set => 'if' succeeded
        it { expect(parsed_results.get("tags")).to include "vcap" }

      end
    end

    describe "failed" do
      when_parsing_log(
          "@source" => {"component" => "some value"}, # bad value
          "@message" => "Some message"
      ) do

        # no tags set => 'if' failed
        it { expect(parsed_results.get("tags")).to be_nil }

        it { expect(parsed_results.get("@type")).to be_nil } # keeps the same
        it { expect(parsed_results.get("@source")["component"]).to eq "some value" } # keeps unchanged
        it { expect(parsed_results.get("@message")).to eq "Some message" } # keeps unchanged

      end
    end

  end

  # -- general case
  describe "#fields when message is" do

    context "plain-text format" do
      when_parsing_log(
          "@source" => {"component" => "vcap.consul-agent"},
          "@level" => "Dummy level",
          # plain-text format
          "@message" => "2016/07/07 00:56:10 [WARN] agent: Check 'service:routing-api' is now critical"
      ) do

        it { expect(parsed_results.get("tags")).to eq ["vcap"] } # vcap tag, no fail tag

        it { expect(parsed_results.get("@type")).to eq "vcap" }

        it { expect(parsed_results.get("@source")["component"]).to eq "consul-agent" }

        it { expect(parsed_results.get("@message"))
                 .to eq "2016/07/07 00:56:10 [WARN] agent: Check 'service:routing-api' is now critical" } # keeps the same value
        it { expect(parsed_results.get("@level")).to eq "Dummy level" } # keeps the same

        it { expect(parsed_results.get("parsed_json_field")).to be_nil } # no json fields
        it { expect(parsed_results.get("parsed_json_field_name")).to be_nil } # no json fields

      end
    end

    context "JSON format" do
      when_parsing_log(
          "@source"=> { "component" => "vcap.nats" },
          # JSON format
          "@message" => "{\"timestamp\":1467852972.554088,\"source\":\"NatsStreamForwarder\",\"log_level\":\"info\",\"message\":\"router.register\",\"data\":{\"nats_message\": \"{\\\"uris\\\":[\\\"redis-broker.64.78.234.207.xip.io\\\"],\\\"host\\\":\\\"192.168.111.201\\\",\\\"port\\\":80}\",\"reply_inbox\":\"_INBOX.7e93f2a1d5115844163cc930b5\"}}"
      ) do

        # no parsing errors
        it { expect(parsed_results.get("tags")).to eq ["vcap"] } # vcap tag, no fail tag

        it { expect(parsed_results.get("@type")).to eq "vcap" }

        it { expect(parsed_results.get("@source")["component"]).to eq "nats" }

        it "sets JSON fields" do
          expect(parsed_results.get("parsed_json_field")).not_to be_nil
          expect(parsed_results.get("parsed_json_field")["timestamp"].to_f).to eq 1467852972.554088
          expect(parsed_results.get("parsed_json_field")["source"]).to eq "NatsStreamForwarder"
          expect(parsed_results.get("parsed_json_field")["data"]["nats_message"]).to eq "{\"uris\":[\"redis-broker.64.78.234.207.xip.io\"],\"host\":\"192.168.111.201\",\"port\":80}"
          expect(parsed_results.get("parsed_json_field")["data"]["reply_inbox"]).to eq "_INBOX.7e93f2a1d5115844163cc930b5"
          expect(parsed_results.get("parsed_json_field_name")).to eq "nats" # set from @source.component
        end

        it "sets @message from JSON" do
          expect(parsed_results.get("@message")).to eq "router.register"
          expect(parsed_results.get("parsed_json_field")["message"]).to be_nil
        end

        it "sets @level from JSON" do
          expect(parsed_results.get("@level")).to eq "info"
          expect(parsed_results.get("parsed_json_field")["log_level"]).to be_nil
        end

      end
    end

    context "JSON format (invalid)" do
      when_parsing_log(
          "@source" => { "component" => "vcap.nats" },
          "@level" => "Dummy value",
          # JSON format
          "@message" => "{\"timestamp\":14678, abcd}}" # invalid JSON
      ) do

        # parsing error
        it { expect(parsed_results.get("tags")).to eq ["vcap", "fail/cloudfoundry/platform-vcap/json"] }

        it { expect(parsed_results.get("@type")).to eq "vcap" }
        it { expect(parsed_results.get("@message")).to eq "{\"timestamp\":14678, abcd}}" } # keeps unchanged
        it { expect(parsed_results.get("@source")["component"]).to eq "nats" } # keeps unchanged
        it { expect(parsed_results.get("@level")).to eq "Dummy value" } # keeps unchanged
        it { expect(parsed_results.get("parsed_json_field")).to be_nil }
        it { expect(parsed_results.get("parsed_json_field_name")).to be_nil }

      end
    end


  end

  describe "#level translate numeric" do

    context "(DEBUG)" do
      when_parsing_log(
          "@source" => {"component" => "vcap.dummy"},
          "@message" => "{\"log_level\":0}"
      ) do

        it { expect(parsed_results.get("@level")).to eq "DEBUG" } # translated

      end
    end

    context "(INFO)" do
      when_parsing_log(
          "@source" => {"component" => "vcap.dummy"},
          "@message" => "{\"log_level\":1}"
      ) do

        it { expect(parsed_results.get("@level")).to eq "INFO" } # translated

      end
    end

    context "(ERROR)" do
      when_parsing_log(
          "@source" => {"component" => "vcap.dummy"},
          "@message" => "{\"log_level\":2}"
      ) do

        it { expect(parsed_results.get("@level")).to eq "ERROR" } # translated

      end
    end

    context "(FATAL)" do
      when_parsing_log(
          "@source" => {"component" => "vcap.dummy"},
          "@message" => "{\"log_level\":3}"
      ) do

        it { expect(parsed_results.get("@level")).to eq "FATAL" } # translated

      end
    end

    context "(fallback)" do
      when_parsing_log(
          "@source" => {"component" => "vcap.dummy"},
          "@message" => "{\"log_level\":8}" # unknown log level
      ) do

        it { expect(parsed_results.get("@level")).to eq "8" } # just converted to string

      end
    end

  end

end
