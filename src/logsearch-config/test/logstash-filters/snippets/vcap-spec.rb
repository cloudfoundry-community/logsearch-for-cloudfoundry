# encoding: utf-8
require 'test/filter_test_helpers'

describe "vcap.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/vcap.conf")}
      }
    CONFIG
  end

  describe "when message is" do

    context "plain-text format" do
      when_parsing_log(
          "@type" => "cf",
          "syslog_program" => "vcap.consul-agent",
          "@source"=> { "component" => "vcap.consul-agent" }, # normally is set in platform.conf
          "@level" => "Dummy level",
          # plain-text format
          "@message" => "2016/07/07 00:56:10 [WARN] agent: Check 'service:routing-api' is now critical"
      ) do

        # fields
        it { expect(subject["@source"]["component"]).to eq "consul-agent" }
        it { expect(subject["@type"]).to eq "vcap_cf" }
        it { expect(subject["tags"]).to eq ["vcap"] }

        it { expect(subject["@message"])
                 .to eq "2016/07/07 00:56:10 [WARN] agent: Check 'service:routing-api' is now critical" } # keeps the same value
        it { expect(subject["@level"]).to eq "Dummy level" } # keeps the same

        it { expect(subject["parsed_json_data"]).to be_nil } # no json fields

      end
    end

    context "JSON format" do
      when_parsing_log(
          "@type" => "cf",
          "syslog_program" => "vcap.nats",
          "@source"=> { "component" => "vcap.nats" }, # normally is set in platform.conf
          # JSON format
          "@message" => "{\"timestamp\":1467852972.554088,\"source\":\"NatsStreamForwarder\",\"log_level\":\"info\",\"message\":\"router.register\",\"data\":{\"nats_message\": \"{\\\"uris\\\":[\\\"redis-broker.64.78.234.207.xip.io\\\"],\\\"host\\\":\\\"192.168.111.201\\\",\\\"port\\\":80}\",\"reply_inbox\":\"_INBOX.7e93f2a1d5115844163cc930b5\"}}"
      ) do

        # fields
        it { expect(subject["@source"]["component"]).to eq "nats" }
        it { expect(subject["@type"]).to eq "vcap_cf" }
        it { expect(subject["tags"]).to eq ["vcap"] }

        # JSON fields
        it "sets JSON fields" do
          expect(subject["parsed_json_data"]).not_to be_nil
          expect(subject["parsed_json_data"]["timestamp"]).to eq 1467852972.554088
          expect(subject["parsed_json_data"]["source"]).to eq "NatsStreamForwarder"
          expect(subject["parsed_json_data"]["data"]["nats_message"]).to eq "{\"uris\":[\"redis-broker.64.78.234.207.xip.io\"],\"host\":\"192.168.111.201\",\"port\":80}"
          expect(subject["parsed_json_data"]["data"]["reply_inbox"]).to eq "_INBOX.7e93f2a1d5115844163cc930b5"
        end

        it "sets @message from JSON" do
          expect(subject["@message"]).to eq "router.register"
          expect(subject["parsed_json_data"]["message"]).to be_nil
        end

        it "sets @level from JSON" do
          expect(subject["@level"]).to eq "info"
          expect(subject["parsed_json_data"]["log_level"]).to be_nil
        end

      end
    end

  end


  describe "when NOT vcap case" do

    context "(bad @type)" do
      event = when_parsing_log(
          "@type" => "Some type", # bad value
          "syslog_program" => "vcap.some_program",
          "@message" => "Some message"
      ) do

        it { expect(subject).to eq event } # kept the same

      end
    end

    context "(bad syslog_program)" do
      event = when_parsing_log(
          "@type" => "cf",
          "syslog_program" => "Some program", # bad value
          "@message" => "Some message"
      ) do

        it { expect(subject).to eq event } # kept the same

      end
    end

    context "(uaa case)" do
      event = when_parsing_log(
          "@type" => "cf",
          "syslog_program" => "vcap.uaa", # bad value
          "@message" => "Some message"
      ) do

        it { expect(subject).to eq event } # kept the same

      end
    end

  end

end
