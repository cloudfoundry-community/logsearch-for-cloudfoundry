# encoding: utf-8
require 'test/filter_test_helpers'

describe "App Integration Test spec" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("target/logstash-filters-default.conf")} # NOTE: we use already built config here
      }
    CONFIG
  end

  describe "checks fields" do

    context "when msg in plain text format" do
      when_parsing_log(
          "@type" => "syslog",
          "syslog_program" => "doppler",
          "syslog_pri" => "6",
          "host" => "bed08922-4734-4d62-9eba-3291aed1b8ce",
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"event_type\":\"LogMessage\",\"level\":\"info\",\"message_type\":\"OUT\",\"msg\":\"{\\\"timestamp\\\":\\\"2016-07-08 10:00:40.073\\\",\\\"level\\\":\\\"INFO\\\",\\\"thread\\\":\\\"main\\\",\\\"logger\\\":\\\"com.altoros.LogGenerator\\\",\\\"message\\\":\\\"Some Message 7892,143\\\"}\",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"App\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        it "checks common fields" do
          expect(subject["@input"]).to eq "syslog"
          expect(subject["@shipper"]["priority"]).to eq "6"
          expect(subject["@shipper"]["name"]).to eq "doppler_syslog"
          expect(subject["@source"]["host"]).to eq "bed08922-4734-4d62-9eba-3291aed1b8ce"
        end

        it "checks common fields overridden by JSON" do
          expect(subject["@source"]["component"]).to eq "App"
        end

        # TODO: verify other fields

      end
    end

  end

end
