# encoding: utf-8
require 'test/filter_test_helpers'

describe "App Integration Test" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("target/logstash-filters-default.conf")} # NOTE: we use already built config here
      }
    CONFIG
  end

  describe "when message is app log" do

    context "(unknown msg format)" do
      when_parsing_log(
          "@type" => "syslog",
          "syslog_program" => "doppler",
          "syslog_pri" => "6",
          "syslog_severity_code" => 3,
          "host" => "bed08922-4734-4d62-9eba-3291aed1b8ce",
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"event_type\":\"LogMessage\",\"level\":\"info\",\"message_type\":\"OUT\",\"msg\":\"Some Message\",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"App\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        # no parsing errors
        it { expect(subject["@tags"]).not_to include "fail/cloudfoundry/firehose/json" }

        # fields
        it "should set common fields" do
          expect(subject["@input"]).to eq "syslog"
          expect(subject["@shipper"]["priority"]).to eq "6"
          expect(subject["@shipper"]["name"]).to eq "doppler_syslog"
          expect(subject["@source"]["host"]).to eq "bed08922-4734-4d62-9eba-3291aed1b8ce"
          expect(subject["@source"]["name"]).to eq "App/0"
          expect(subject["@source"]["instance"]).to eq 0

          expect(subject["@metadata"]["index"]).to eq "app-admin-demo"
        end

        it "should override common fields" do
          expect(subject["@source"]["component"]).to eq "App"
          expect(subject["@type"]).to eq "LogMessage"
          expect(subject["@tags"]).to include "app"
        end

        it "should set mandatory fields" do
          expect(subject["@message"]).to eq "Some Message"
          expect(subject["@level"]).to eq "INFO"
        end

        it "should set app specific fields" do
          expect(subject["@source"]["app"]).to eq "loggenerator"
          expect(subject["@source"]["app_id"]).to eq "31b928ee-4110-4e7b-996c-334c5d7ac2ac"
          expect(subject["@source"]["space"]).to eq "demo"
          expect(subject["@source"]["space_id"]).to eq "59cf41f2-3a1d-42db-88e7-9540b02945e8"
          expect(subject["@source"]["org"]).to eq "admin"
          expect(subject["@source"]["org_id"]).to eq "9887ad0a-f9f7-449e-8982-76307bd17239"
          expect(subject["@source"]["origin"]).to eq "dea_logging_agent"
          expect(subject["@source"]["message_type"]).to eq "OUT"
        end

        it { expect(subject["@tags"]).to include "unknown_msg_format" }

      end
    end

    context "(JSON msg)" do
      when_parsing_log(
          "@type" => "syslog",
          "syslog_program" => "doppler",
          "syslog_pri" => "6",
          "syslog_severity_code" => 3,
          "host" => "bed08922-4734-4d62-9eba-3291aed1b8ce",
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"event_type\":\"LogMessage\",\"level\":\"info\",\"message_type\":\"OUT\",\"msg\":\"Some Message\",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"App\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        # no parsing errors
        it { expect(subject["@tags"]).not_to include "fail/cloudfoundry/firehose/json" }

        # fields
        it "should set common fields" do
          expect(subject["@input"]).to eq "syslog"
          expect(subject["@shipper"]["priority"]).to eq "6"
          expect(subject["@shipper"]["name"]).to eq "doppler_syslog"
          expect(subject["@source"]["host"]).to eq "bed08922-4734-4d62-9eba-3291aed1b8ce"
          expect(subject["@source"]["name"]).to eq "App/0"
          expect(subject["@source"]["instance"]).to eq 0

          expect(subject["@metadata"]["index"]).to eq "app-admin-demo"
        end

        it "should override common fields" do
          expect(subject["@source"]["component"]).to eq "App"
          expect(subject["@type"]).to eq "LogMessage"
          expect(subject["@tags"]).to include "app"
        end

        it "should set mandatory fields" do
          expect(subject["@level"]).to eq "INFO"
          expect(subject["@message"]).to eq "Some Message"
        end

        it "should set app specific fields" do
          expect(subject["@source"]["app"]).to eq "loggenerator"
          expect(subject["@source"]["app_id"]).to eq "31b928ee-4110-4e7b-996c-334c5d7ac2ac"
          expect(subject["@source"]["space"]).to eq "demo"
          expect(subject["@source"]["space_id"]).to eq "59cf41f2-3a1d-42db-88e7-9540b02945e8"
          expect(subject["@source"]["org"]).to eq "admin"
          expect(subject["@source"]["org_id"]).to eq "9887ad0a-f9f7-449e-8982-76307bd17239"
          expect(subject["@source"]["origin"]).to eq "dea_logging_agent"
          expect(subject["@source"]["message_type"]).to eq "OUT"
        end

        it { expect(subject["@tags"]).to include "unknown_msg_format" }

      end
    end

    context "([CONTAINER] log)" do
      when_parsing_log(
          "@type" => "syslog",
          "syslog_program" => "doppler",
          "syslog_pri" => "6",
          "syslog_severity_code" => 3,
          "host" => "bed08922-4734-4d62-9eba-3291aed1b8ce",
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"event_type\":\"LogMessage\",\"level\":\"info\",\"message_type\":\"OUT\",\"msg\":\"[CONTAINER] org.apache.catalina.startup.Catalina               DEBUG    Server startup in 9775 ms\",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"App\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        # no parsing errors
        it { expect(subject["@tags"]).not_to include "fail/cloudfoundry/firehose/json" }

        # fields
        it "should set common fields" do
          expect(subject["@input"]).to eq "syslog"
          expect(subject["@shipper"]["priority"]).to eq "6"
          expect(subject["@shipper"]["name"]).to eq "doppler_syslog"
          expect(subject["@source"]["host"]).to eq "bed08922-4734-4d62-9eba-3291aed1b8ce"
          expect(subject["@source"]["name"]).to eq "App/0"
          expect(subject["@source"]["instance"]).to eq 0

          expect(subject["@metadata"]["index"]).to eq "app-admin-demo"
        end

        it "should override common fields" do
          expect(subject["@source"]["component"]).to eq "App"
          expect(subject["@type"]).to eq "LogMessage"
          expect(subject["@tags"]).to include "app"
        end

        it "should set app specific fields" do
          expect(subject["@source"]["app"]).to eq "loggenerator"
          expect(subject["@source"]["app_id"]).to eq "31b928ee-4110-4e7b-996c-334c5d7ac2ac"
          expect(subject["@source"]["space"]).to eq "demo"
          expect(subject["@source"]["space_id"]).to eq "59cf41f2-3a1d-42db-88e7-9540b02945e8"
          expect(subject["@source"]["org"]).to eq "admin"
          expect(subject["@source"]["org_id"]).to eq "9887ad0a-f9f7-449e-8982-76307bd17239"
          expect(subject["@source"]["origin"]).to eq "dea_logging_agent"
          expect(subject["@source"]["message_type"]).to eq "OUT"
        end

        # format-specific
        it { expect(subject["@tags"]).to_not include "unknown_msg_format" }

        it "should override mandatory fields from JSON msg" do
          expect(subject["@message"]).to eq "Server startup in 9775 ms"
          expect(subject["@level"]).to eq "DEBUG"
        end

        it "should set logger field" do
          expect(subject["log"]["logger"]).to eq "[CONTAINER] org.apache.catalina.startup.Catalina"
        end

      end
    end

    context "(Logback status log)" do
      when_parsing_log(
          "@type" => "syslog",
          "syslog_program" => "doppler",
          "syslog_pri" => "6",
          "syslog_severity_code" => 3,
          "host" => "bed08922-4734-4d62-9eba-3291aed1b8ce",
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"event_type\":\"LogMessage\",\"level\":\"info\",\"message_type\":\"OUT\",\"msg\":\"16:41:17,033 |-DEBUG in ch.qos.logback.classic.joran.action.RootLoggerAction - Setting level of ROOT logger to WARN\",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"App\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        # no parsing errors
        it { expect(subject["@tags"]).not_to include "fail/cloudfoundry/firehose/json" }

        # fields
        it "should set common fields" do
          expect(subject["@input"]).to eq "syslog"
          expect(subject["@shipper"]["priority"]).to eq "6"
          expect(subject["@shipper"]["name"]).to eq "doppler_syslog"
          expect(subject["@source"]["host"]).to eq "bed08922-4734-4d62-9eba-3291aed1b8ce"
          expect(subject["@source"]["name"]).to eq "App/0"
          expect(subject["@source"]["instance"]).to eq 0

          expect(subject["@metadata"]["index"]).to eq "app-admin-demo"
        end

        it "should override common fields" do
          expect(subject["@source"]["component"]).to eq "App"
          expect(subject["@type"]).to eq "LogMessage"
          expect(subject["@tags"]).to include "app"
        end

        it "should set app specific fields" do
          expect(subject["@source"]["app"]).to eq "loggenerator"
          expect(subject["@source"]["app_id"]).to eq "31b928ee-4110-4e7b-996c-334c5d7ac2ac"
          expect(subject["@source"]["space"]).to eq "demo"
          expect(subject["@source"]["space_id"]).to eq "59cf41f2-3a1d-42db-88e7-9540b02945e8"
          expect(subject["@source"]["org"]).to eq "admin"
          expect(subject["@source"]["org_id"]).to eq "9887ad0a-f9f7-449e-8982-76307bd17239"
          expect(subject["@source"]["origin"]).to eq "dea_logging_agent"
          expect(subject["@source"]["message_type"]).to eq "OUT"
        end

        # format-specific
        it { expect(subject["@tags"]).to_not include "unknown_msg_format" }

        it "should override mandatory fields from JSON msg" do
          expect(subject["@message"]).to eq "Setting level of ROOT logger to WARN"
          expect(subject["@level"]).to eq "DEBUG"
        end

        it "should set logger field" do
          expect(subject["log"]["logger"]).to eq "ch.qos.logback.classic.joran.action.RootLoggerAction"
        end

      end
    end

  end

end
