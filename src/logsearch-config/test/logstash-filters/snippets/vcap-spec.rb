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
          # plain-text format
          "@message" => "2016/07/07 00:56:10 [WARN] agent: Check 'service:routing-api' is now critical"
      ) do

        # fields

        it { expect(subject["vcap"]).to be_nil }

        it { expect(subject["@message"])
          .to eq "2016/07/07 00:56:10 [WARN] agent: Check 'service:routing-api' is now critical" } # keeps the same value

        it "should set general fields" do
          expect(subject["@source"]["component"]).to eq "consul-agent"
          expect(subject["@type"]).to eq "vcap_cf"
          expect(subject["tags"]).to include "vcap"
        end

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
        it "should set [vcap] fields from JSON" do
          expect(subject["vcap"]).not_to be_nil
          expect(subject["vcap"]["timestamp"]).to eq 1467852972.554088
          expect(subject["vcap"]["source"]).to eq "NatsStreamForwarder"
          expect(subject["vcap"]["data"]["nats_message"]).to eq "{\"uris\":[\"redis-broker.64.78.234.207.xip.io\"],\"host\":\"192.168.111.201\",\"port\":80}"
          expect(subject["vcap"]["data"]["reply_inbox"]).to eq "_INBOX.7e93f2a1d5115844163cc930b5"
        end

        it "should set @message from JSON" do
          expect(subject["@message"]).to eq "router.register"
          expect(subject["vcap"]["message"]).to be_nil
        end

        it "should set @level from JSON" do
          expect(subject["@level"]).to eq "info"
          expect(subject["vcap"]["log_level"]).to be_nil
        end

        it "should set general fields" do
          expect(subject["@source"]["component"]).to eq "nats"
          expect(subject["@type"]).to eq "vcap_cf"
          expect(subject["tags"]).to include "vcap"
        end

      end
    end

  end


  describe "when NOT vcap case" do

    context "(bad @type)" do
      when_parsing_log(
          "@type" => "Some type", # bad value
          "syslog_program" => "vcap.some_program",
          "@message" => "Some message"
      ) do

        # fields not set => 'if' condition has failed
        it "shouldn't set fields" do
          expect(subject["vcap"]).to be_nil
          expect(subject["@source"]).to be_nil
          expect(subject["tags"]).to be_nil
          expect(subject["@type"]).to eq "Some type" # kept the same
          expect(subject["@message"]).to eq "Some message" # kept the same
        end

      end
    end

    context "(bad syslog_program)" do
      when_parsing_log(
          "@type" => "cf",
          "syslog_program" => "Some program", # bad value
          "@message" => "Some message"
      ) do

        # fields not set => 'if' condition has failed
        it "shouldn't set fields" do
          expect(subject["vcap"]).to be_nil
          expect(subject["@source"]).to be_nil
          expect(subject["tags"]).to be_nil
          expect(subject["@type"]).to eq "cf" # kept the same
          expect(subject["@message"]).to eq "Some message" # kept the same
        end

      end
    end

    context "(uaa case)" do
      when_parsing_log(
          "@type" => "cf",
          "syslog_program" => "vcap.uaa", # bad value
          "@message" => "Some message"
      ) do

        # fields not set => 'if' condition has failed
        it "shouldn't set fields" do
          expect(subject["vcap"]).to be_nil
          expect(subject["@source"]).to be_nil
          expect(subject["tags"]).to be_nil
          expect(subject["@type"]).to eq "cf" # kept the same
          expect(subject["@message"]).to eq "Some message" # kept the same
        end

      end
    end

  end

end
