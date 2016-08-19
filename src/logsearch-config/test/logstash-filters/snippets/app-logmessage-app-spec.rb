# encoding: utf-8
require 'test/logstash-filters/filter_test_helpers'

describe "app-logmessage-app.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/app-logmessage-app.conf")}
      }
    CONFIG
  end

  describe "#if failed" do

    context "(bad @type)" do
      when_parsing_log(
          "@type" => "Some type", # bad value
          "@source" => {"type" => "APP"},
          "@level" => "INFO",
          "@message" => "Some message of wrong format"
      ) do

        # no tags => 'if' condition has failed
        it { expect(subject["tags"]).to be_nil }

      end
    end

    context "(bad [@source][type])" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => {"type" => "Some value"}, # bad value
          "@level" => "INFO",
          "@message" => "Some message of wrong format"
      ) do

        # no log tags => 'if' condition has failed
        it { expect(subject["tags"]).to be_nil }

      end
    end

    context "(lowercase [@source][type])" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => {"type" => "App"}, # lowercase - bad value
          "@level" => "INFO",
          "@message" => "Some message of wrong format"
      ) do

        # no log tags => 'if' condition has failed
        it { expect(subject["tags"]).to be_nil }

      end
    end
  end

  # -- general case
  describe "#fields when message is" do

    describe "JSON format" do
      context "(general)" do
        when_parsing_log(
            "@type" => "LogMessage",
            "@source" => { "type" => "APP" },
            "@level" => "SOME LEVEL",
            # JSON format (general)
            "@message" => "{\"timestamp\":\"2016-07-15 13:20:16.954\",\"level\":\"INFO\",\"thread\":\"main\",\"logger\":\"com.abc.LogGenerator\",\"message\":\"Some message\"}"
        ) do

          # no parsing errors
          it { expect(subject["tags"]).to eq ["logmessage-app"] } # no fail tag

          # fields
          it "sets @message" do
            expect(subject["@message"]).to eq "Some message"
            expect(subject["app"]["message"]).to be_nil
          end

          it "sets @level" do
            expect(subject["@level"]).to eq "INFO"
            expect(subject["app"]["level"]).to be_nil
          end

          it "sets fields from JSON" do
            expect(subject["app"]["timestamp"]).to eq "2016-07-15 13:20:16.954"
            expect(subject["app"]["thread"]).to eq "main"
            expect(subject["app"]["logger"]).to eq "com.abc.LogGenerator"
          end

        end
      end

      context "(with exception)" do
        when_parsing_log(
            "@type" => "LogMessage",
            "@source" => { "type" => "APP" },
            "@level" => "SOME LEVEL",
            # JSON format (with exception)
            "@message" => "{\"message\":\"Some error\", \"exception\":\"Some exception\"}"
        ) do

          it "appends exception to message" do
            expect(subject["@message"]).to eq "Some error
Some exception"
            expect(subject["app"]).to be_empty
          end

        end
      end

      context "(invalid)" do
        when_parsing_log(
            "@type" => "LogMessage",
            "@source" => { "type" => "APP" },
            "@level" => "SOME LEVEL",
            "@message" => "{\"message\":\"Some message\", }" # invalid JSON
        ) do

          # unknown_message_format
          it { expect(subject["tags"]).to eq ["logmessage-app", "unknown_msg_format"] }

          it { expect(subject["@message"]).to eq "{\"message\":\"Some message\", }" } # keeps unchanged
          it { expect(subject["@level"]).to eq "SOME LEVEL" } # keeps unchanged

        end
      end

      context "(empty)" do
        when_parsing_log(
            "@type" => "LogMessage",
            "@source" => { "type" => "APP" },
            "@level" => "SOME LEVEL",
            "@message" => "{}" # empty JSON
        ) do

          # unknown_message_format tag
          it { expect(subject["tags"]).to eq ["logmessage-app", "unknown_msg_format"] }

          it { expect(subject["@message"]).to eq "{}" } # keeps unchanged
          it { expect(subject["@level"]).to eq "SOME LEVEL" } # keeps unchanged

        end
      end

    end

    describe "[CONTAINER] log" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "type" => "APP" },
          "@level" => "SOME LEVEL",
          # [CONTAINER] log
          "@message" => "[CONTAINER] org.apache.catalina.startup.Catalina               INFO    Server startup in 9775 ms"
      ) do

        # no parsing errors
        it { expect(subject["tags"]).to eq ["logmessage-app"] } # no unknown_msg_format tag

        it "sets fields from 'grok'" do
          expect(subject["@message"]).to eq "Server startup in 9775 ms"
          expect(subject["@level"]).to eq "INFO"
          expect(subject["app"]["logger"]).to eq "[CONTAINER] org.apache.catalina.startup.Catalina"
        end

      end
    end

    describe "Logback status log" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "type" => "APP" },
          "@level" => "SOME LEVEL",
          # Logback status log
          "@message" => "16:41:17,033 |-DEBUG in ch.qos.logback.classic.joran.action.RootLoggerAction - Setting level of ROOT logger to WARN"
      ) do

        # no parsing errors
        it { expect(subject["tags"]).to eq ["logmessage-app"] } # no unknown_msg_format tag

        it "sets fields from 'grok'" do
          expect(subject["@message"]).to eq "Setting level of ROOT logger to WARN"
          expect(subject["@level"]).to eq "DEBUG"
          expect(subject["app"]["logger"]).to eq "ch.qos.logback.classic.joran.action.RootLoggerAction"
        end

      end
    end

    describe "unknown format" do

      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "type" => "APP" },
          "@level" => "SOME LEVEL",
          "@message" => "Some Message" # unknown format
      ) do

        # unknown format
        it { expect(subject["tags"]).to eq ["logmessage-app", "unknown_msg_format"] }

        it { expect(subject["@message"]).to eq "Some Message" } # keeps unchanged
        it { expect(subject["@level"]).to eq "SOME LEVEL" } # keeps unchanged

      end
    end

  end

end
