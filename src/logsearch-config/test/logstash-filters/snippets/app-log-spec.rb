# encoding: utf-8
require 'test/logstash-filters/filter_test_helpers'

describe "app-log.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/app-log.conf")}
      }
    CONFIG
  end

  describe "#if" do

    context "failed (bad @type)" do
      when_parsing_log(
          "@type" => "Some type", # bad value
          "@source" => {"component" => "APP"},
          "@level" => "INFO",
          "@message" => "Some message of wrong format"
      ) do

        # no log tags => 'if' condition has failed
        it { expect(subject["tags"]).to be_nil }

      end
    end

    context "failed (bad [@source][component])" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => {"component" => "Some value"}, # bad value
          "@level" => "INFO",
          "@message" => "Some message of wrong format"
      ) do

        # no log tags => 'if' condition has failed
        it { expect(subject["tags"]).to be_nil }

      end
    end

    context "failed (lowercase [@source][component])" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => {"component" => "App"}, # lowercase - bad value
          "@level" => "INFO",
          "@message" => "Some message of wrong format"
      ) do

        # no log tags => 'if' condition has failed
        it { expect(subject["tags"]).to be_nil }

      end
    end
  end

  describe "drop/keep event" do

    context "when 'msg' is useless (empty) - drop" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "component" => "APP" },
          "@message" => "" # empty message
      ) do

        # useless event was dropped
        it { expect(subject).to be_nil }

      end
    end

    context "when 'msg' is useless (blank) - drop" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "component" => "APP" },
          "@message" => "   " # blank message
      ) do

        # useless event was dropped
        it { expect(subject).to be_nil }

      end
    end

    context "when @message is just missing - keep" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "component" => "APP" }
          # no @message field at all
      ) do

        # event was NOT dropped
        it { expect(subject).not_to be_nil }

      end
    end

  end

  describe "when message is" do

    describe "JSON format" do
      context "(general)" do
        when_parsing_log(
            "@type" => "LogMessage", # good type
            "@source" => { "component" => "APP" }, # good component
            "@level" => "SOME LEVEL",
            # JSON format (general)
            "@message" => "{\"timestamp\":\"2016-07-15 13:20:16.954\",\"level\":\"INFO\",\"thread\":\"main\",\"logger\":\"com.abc.LogGenerator\",\"message\":\"Some message\"}"
        ) do

          # no parsing errors
          it { expect(subject["tags"]).to eq ["log"] } # no fail tag

          # fields
          it "sets @message" do
            expect(subject["@message"]).to eq "Some message"
            expect(subject["log"]["message"]).to be_nil
          end

          it "sets @level" do
            expect(subject["@level"]).to eq "INFO"
            expect(subject["log"]["level"]).to be_nil
          end

          it "sets [log] fields from JSON" do
            expect(subject["log"]["timestamp"]).to eq "2016-07-15 13:20:16.954"
            expect(subject["log"]["thread"]).to eq "main"
            expect(subject["log"]["logger"]).to eq "com.abc.LogGenerator"
          end

        end
      end

      context "(with exception)" do
        when_parsing_log(
            "@type" => "LogMessage",
            "@source" => { "component" => "APP" },
            "@level" => "SOME LEVEL",
            # JSON format (with exception)
            "@message" => "{\"message\":\"Some error\", \"exception\":\"Some exception\"}"
        ) do

          it "appends exception to message" do
            expect(subject["@message"]).to eq "Some error
Some exception"
            expect(subject["log"]).to be_empty
          end

        end
      end

      context "(invalid)" do
        when_parsing_log(
            "@type" => "LogMessage",
            "@source" => { "component" => "APP" },
            "@level" => "SOME LEVEL",
            "@message" => "{\"message\":\"Some message\", }" # invalid JSON
        ) do

          # unknown_message_format
          it { expect(subject["tags"]).to eq ["log", "unknown_msg_format"] }

          it { expect(subject["@message"]).to eq "{\"message\":\"Some message\", }" } # keeps unchanged
          it { expect(subject["@level"]).to eq "SOME LEVEL" } # keeps unchanged

        end
      end

      context "(empty)" do
        when_parsing_log(
            "@type" => "LogMessage",
            "@source" => { "component" => "APP" },
            "@level" => "SOME LEVEL",
            "@message" => "{}" # empty JSON
        ) do

          # unknown_message_format tag
          it { expect(subject["tags"]).to eq ["log", "unknown_msg_format"] }

          it { expect(subject["@message"]).to eq "{}" } # keeps unchanged
          it { expect(subject["@level"]).to eq "SOME LEVEL" } # keeps unchanged

        end
      end

    end

    describe "[CONTAINER] log" do
      when_parsing_log(
          "@type" => "LogMessage", # good type
          "@source" => { "component" => "APP" }, # good component
          "@level" => "SOME LEVEL",
          # [CONTAINER] log
          "@message" => "[CONTAINER] org.apache.catalina.startup.Catalina               INFO    Server startup in 9775 ms"
      ) do

        # no parsing errors
        it { expect(subject["tags"]).to eq ["log"] } # no unknown_msg_format tag

        it "sets fields from 'grok'" do
          expect(subject["@message"]).to eq "Server startup in 9775 ms"
          expect(subject["@level"]).to eq "INFO"
          expect(subject["log"]["logger"]).to eq "[CONTAINER] org.apache.catalina.startup.Catalina"
        end

      end
    end

    describe "Logback status log" do
      when_parsing_log(
          "@type" => "LogMessage", # good type
          "@source" => { "component" => "APP" }, # good component
          "@level" => "SOME LEVEL",
          # Logback status log
          "@message" => "16:41:17,033 |-DEBUG in ch.qos.logback.classic.joran.action.RootLoggerAction - Setting level of ROOT logger to WARN"
      ) do

        # no parsing errors
        it { expect(subject["tags"]).to eq ["log"] } # no unknown_msg_format tag

        it "sets fields from 'grok'" do
          expect(subject["@message"]).to eq "Setting level of ROOT logger to WARN"
          expect(subject["@level"]).to eq "DEBUG"
          expect(subject["log"]["logger"]).to eq "ch.qos.logback.classic.joran.action.RootLoggerAction"
        end

      end
    end

    describe "unknown format" do

      when_parsing_log(
          "@type" => "LogMessage", # good type
          "@source" => { "component" => "APP" }, # good component
          "@level" => "SOME LEVEL",
          "@message" => "Some Message" # unknown format
      ) do

        # unknown format
        it { expect(subject["tags"]).to eq ["log", "unknown_msg_format"] }

        it { expect(subject["@message"]).to eq "Some Message" } # keeps unchanged
        it { expect(subject["@level"]).to eq "SOME LEVEL" } # keeps unchanged

      end
    end

  end

end
