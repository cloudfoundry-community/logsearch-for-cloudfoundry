# encoding: utf-8
require 'test/filter_test_helpers'

describe "app-log.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/app-log.conf")}
      }
    CONFIG
  end

  describe "when message is JSON format" do
    context "(general)" do
      when_parsing_log(
          "@type" => "LogMessage", # good type
          "@source" => { "component" => "App" }, # good component
          "@level" => "SOME LEVEL",
          # JSON format (general)
          "@message" => "{\"timestamp\":\"2016-07-15 13:20:16.954\",\"level\":\"INFO\",\"thread\":\"main\",\"logger\":\"com.abc.LogGenerator\",\"message\":\"Some message\"}"
      ) do

        # log tag only (no fail tags)
        it { expect(subject["tags"]).to eq ["log"] }

        it "should override fields from JSON" do
          expect(subject["@message"]).to eq "Some message"
          expect(subject["@level"]).to eq "INFO"
          expect(subject["log"]["message"]).to be_nil
          expect(subject["log"]["level"]).to be_nil
        end

        it "should set [log] fields from JSON" do
          expect(subject["log"]["timestamp"]).to eq "2016-07-15 13:20:16.954"
          expect(subject["log"]["thread"]).to eq "main"
          expect(subject["log"]["logger"]).to eq "com.abc.LogGenerator"
        end

      end
    end

    context "(with exception)" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "component" => "App" },
          "@level" => "SOME LEVEL",
          # JSON format (with exception)
          "@message" => "{\"message\":\"Some error\", \"exception\":\"Some exception\"}"
      ) do

        it "should append exception to message" do
          expect(subject["@message"]).to eq "Some error
Some exception"
          expect(subject["log"]).to be_empty
        end

      end
    end

    context "(invalid)" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "component" => "App" },
          "@level" => "SOME LEVEL",
          "@message" => "{\"message\":\"Some message\", }" # invalid JSON
      ) do

        # log tag only & unknown_message_format tag
        it { expect(subject["tags"]).to eq ["log", "unknown_msg_format"] }

        it "should not override fields" do
          expect(subject["@message"]).to eq "{\"message\":\"Some message\", }"
          expect(subject["@level"]).to eq "SOME LEVEL"
        end

      end
    end

    context "(empty)" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => { "component" => "App" },
          "@level" => "SOME LEVEL",
          "@message" => "{}" # empty JSON
      ) do

        # log tag only & unknown_message_format tag
        it { expect(subject["tags"]).to eq ["log", "unknown_msg_format"] }

        it "should not override fields" do
          expect(subject["@message"]).to eq "{}"
          expect(subject["@level"]).to eq "SOME LEVEL"
        end

      end
    end

  end

  describe "when message is [CONTAINER] log" do
    when_parsing_log(
        "@type" => "LogMessage", # good type
        "@source" => { "component" => "App" }, # good component
        "@level" => "SOME LEVEL",
        # [CONTAINER] log
        "@message" => "[CONTAINER] org.apache.catalina.startup.Catalina               INFO    Server startup in 9775 ms"
    ) do

      # log tag only (no fail tags)
      it { expect(subject["tags"]).to eq ["log"] }

      it "should set fields from 'grok'" do
        expect(subject["@message"]).to eq "Server startup in 9775 ms"
        expect(subject["@level"]).to eq "INFO"
        expect(subject["log"]["logger"]).to eq "[CONTAINER] org.apache.catalina.startup.Catalina"
      end

    end
  end

  describe "when message is Logback status log" do
    when_parsing_log(
        "@type" => "LogMessage", # good type
        "@source" => { "component" => "App" }, # good component
        "@level" => "SOME LEVEL",
        # Logback status log
        "@message" => "16:41:17,033 |-DEBUG in ch.qos.logback.classic.joran.action.RootLoggerAction - Setting level of ROOT logger to WARN"
    ) do

      # log tag only (no fail tags)
      it { expect(subject["tags"]).to eq ["log"] }

      it "should set fields from 'grok'" do
        expect(subject["@message"]).to eq "Setting level of ROOT logger to WARN"
        expect(subject["@level"]).to eq "DEBUG"
        expect(subject["log"]["logger"]).to eq "ch.qos.logback.classic.joran.action.RootLoggerAction"
      end

    end
  end

  describe "when message is unknown format" do

    when_parsing_log(
        "@type" => "LogMessage", # good type
        "@source" => { "component" => "App" }, # good component
        "@level" => "SOME LEVEL",
        "@message" => "Some Message" # unknown format
    ) do

      # log tag, unknown_msg_format tag
      it { expect(subject["tags"]).to eq ["log", "unknown_msg_format"] }

      it "should keep fields" do
        expect(subject["@message"]).to eq "Some Message"
        expect(subject["@level"]).to eq "SOME LEVEL"
      end

    end
  end


  describe "when NOT app log case" do

    context "(bad @type)" do
      when_parsing_log(
          "@type" => "Some type", # bad value
          "@source" => {"component" => "App"},
          "@level" => "INFO",
          "@message" => "Some message of wrong format"
      ) do

        # no log tags => 'if' condition has failed
        it { expect(subject["tags"]).to be_nil }

      end
    end

    context "(bad [@source][component])" do
      when_parsing_log(
          "@type" => "LogMessage",
          "@source" => {"component" => "Bad value"}, # bad value
          "@level" => "INFO",
          "@message" => "Some message of wrong format"
      ) do

        # no log tags => 'if' condition has failed
        it { expect(subject["tags"]).to be_nil }

      end
    end

  end

end
