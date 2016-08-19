# encoding: utf-8
require 'test/logstash-filters/filter_test_helpers'

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
        it { expect(subject["tags"]).to include "vcap" }

      end
    end

    describe "failed" do
      when_parsing_log(
          "@source" => {"component" => "some value"}, # bad value
          "@message" => "Some message"
      ) do

        # no tags set => 'if' failed
        it { expect(subject["tags"]).to be_nil }

        it { expect(subject["@type"]).to be_nil } # keeps the same
        it { expect(subject["@source"]["component"]).to eq "some value" } # keeps unchanged
        it { expect(subject["@message"]).to eq "Some message" } # keeps unchanged

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

        it { expect(subject["tags"]).to eq ["vcap"] } # vcap tag, no fail tag

        it { expect(subject["@type"]).to eq "vcap" }

        it { expect(subject["@source"]["component"]).to eq "consul-agent" }

        it { expect(subject["@message"])
                 .to eq "2016/07/07 00:56:10 [WARN] agent: Check 'service:routing-api' is now critical" } # keeps the same value
        it { expect(subject["@level"]).to eq "Dummy level" } # keeps the same

        it { expect(subject["parsed_json_field"]).to be_nil } # no json fields
        it { expect(subject["parsed_json_field_name"]).to be_nil } # no json fields

      end
    end

    context "JSON format" do
      when_parsing_log(
          "@source"=> { "component" => "vcap.nats" },
          # JSON format
          "@message" => "{\"timestamp\":1467852972.554088,\"source\":\"NatsStreamForwarder\",\"log_level\":\"info\",\"message\":\"router.register\",\"data\":{\"nats_message\": \"{\\\"uris\\\":[\\\"redis-broker.64.78.234.207.xip.io\\\"],\\\"host\\\":\\\"192.168.111.201\\\",\\\"port\\\":80}\",\"reply_inbox\":\"_INBOX.7e93f2a1d5115844163cc930b5\"}}"
      ) do

        # no parsing errors
        it { expect(subject["tags"]).to eq ["vcap"] } # vcap tag, no fail tag

        it { expect(subject["@type"]).to eq "vcap" }

        it { expect(subject["@source"]["component"]).to eq "nats" }

        it "sets JSON fields" do
          expect(subject["parsed_json_field"]).not_to be_nil
          expect(subject["parsed_json_field"]["timestamp"]).to eq 1467852972.554088
          expect(subject["parsed_json_field"]["source"]).to eq "NatsStreamForwarder"
          expect(subject["parsed_json_field"]["data"]["nats_message"]).to eq "{\"uris\":[\"redis-broker.64.78.234.207.xip.io\"],\"host\":\"192.168.111.201\",\"port\":80}"
          expect(subject["parsed_json_field"]["data"]["reply_inbox"]).to eq "_INBOX.7e93f2a1d5115844163cc930b5"
          expect(subject["parsed_json_field_name"]).to eq "nats" # set from @source.component
        end

        it "sets @message from JSON" do
          expect(subject["@message"]).to eq "router.register"
          expect(subject["parsed_json_field"]["message"]).to be_nil
        end

        it "sets @level from JSON" do
          expect(subject["@level"]).to eq "info"
          expect(subject["parsed_json_field"]["log_level"]).to be_nil
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
        it { expect(subject["tags"]).to eq ["vcap", "fail/cloudfoundry/platform-vcap/json"] }

        it { expect(subject["@type"]).to eq "vcap" }
        it { expect(subject["@message"]).to eq "{\"timestamp\":14678, abcd}}" } # keeps unchanged
        it { expect(subject["@source"]["component"]).to eq "nats" } # keeps unchanged
        it { expect(subject["@level"]).to eq "Dummy value" } # keeps unchanged
        it { expect(subject["parsed_json_field"]).to be_nil }
        it { expect(subject["parsed_json_field_name"]).to be_nil }

      end
    end


  end

end
