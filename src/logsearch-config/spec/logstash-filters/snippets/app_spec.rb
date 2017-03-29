# encoding: utf-8
require 'spec_helper'

describe "app.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/app.conf")}
      }
    CONFIG
  end

  describe "#if" do

    describe "passed" do
      when_parsing_log(
          "@index_type" => "app", # good value
          "@message" => "Some message"
      ) do

        # tag set => 'if' succeeded
        it { expect(parsed_results.get("tags")).to include "app" }

      end
    end

    describe "failed" do
      when_parsing_log(
          "@index_type" => "some value", # bad value
          "@message" => "Some message"
      ) do

        # no tags set => 'if' failed
        it { expect(parsed_results.get("tags")).to be_nil }

        it { expect(parsed_results.get("@index_type")).to eq "some value" } # keeps unchanged
        it { expect(parsed_results.get("@message")).to eq "Some message" } # keeps unchanged

      end
    end

  end

  # -- general case
  describe "#fields when json" do

    context "succeeded" do
      when_parsing_log(
          "@index_type" => "app",
          "@metadata" => {"index" => "app"},
          # valid JSON (LogMessage event)
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\", \"deployment\":\"cf-full\", \"event_type\":\"LogMessage\", \"job_index\":\"abc123\",\"ip\":\"192.168.111.35\", \"job\":\"runner_z1\", \"level\":\"info\",\"message_type\":\"OUT\",\"msg\":\"Some Message\",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"APP\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        # no parsing errors
        it { expect(parsed_results.get("tags")).not_to include "fail/cloudfoundry/app/json" }
        it { expect(parsed_results.get("tags")).to include "app" }

        # fields

        it { expect(parsed_results.get("parsed_json_field")["time"]).to be_nil }
        it { expect(parsed_results.get("parsed_json_field")["timestamp"]).to be_nil }

        it { expect(parsed_results.get("tags")).not_to include('_rubyexception') }

        it { expect(parsed_results.get("@message")).to eq "Some Message" }
        it { expect(parsed_results.get("@level")).to eq "info" }

        it "sets @source fields" do
          expect(parsed_results.get("@source")["type"]).to eq "LOG"
          expect(parsed_results.get("@source")["component"]).to eq "dea_logging_agent"
          expect(parsed_results.get("@source")["job_index"]).to eq "abc123"
          expect(parsed_results.get("@source")["job"]).to eq "runner_z1"
          expect(parsed_results.get("@source")["host"]).to eq "192.168.111.35"
          expect(parsed_results.get("@source")["deployment"]).to eq "cf-full"
        end

        it { expect(parsed_results.get("@type")).to eq "LogMessage" }

        it "sets @cf fields" do
          expect(parsed_results.get("@cf")["app"]).to eq "loggenerator"
          expect(parsed_results.get("@cf")["app_id"]).to eq "31b928ee-4110-4e7b-996c-334c5d7ac2ac"
          expect(parsed_results.get("@cf")["space"]).to eq "demo"
          expect(parsed_results.get("@cf")["space_id"]).to eq "59cf41f2-3a1d-42db-88e7-9540b02945e8"
          expect(parsed_results.get("@cf")["org"]).to eq "admin"
          expect(parsed_results.get("@cf")["org_id"]).to eq "9887ad0a-f9f7-449e-8982-76307bd17239"
        end

        it { expect(parsed_results.get("parsed_json_field")["message_type"]).to eq "OUT" }
        it { expect(parsed_results.get("parsed_json_field_name")).to eq "LogMessage" } # @type

        it { expect(parsed_results.get("@index_type")).to eq "app" } # keeps unchanged
        it { expect(parsed_results.get("@metadata")["index"]).to eq "app-admin-demo" }

      end
    end

    context "failed" do
      when_parsing_log(
          "@index_type" => "app",
          # invalid JSON
          "@message" => "Some message that is invalid json"
      ) do

        # parsing error
        it { expect(parsed_results.get("tags")).to include "fail/cloudfoundry/app/json" }
        it { expect(parsed_results.get("tags")).to include "app" }

        it { expect(parsed_results.get("@message")).to eq "Some message that is invalid json" } # keeps unchanged

        # no json fields set
        it { expect(parsed_results.get("@source")).to be_nil }
        it { expect(parsed_results.get("@cf")).to be_nil }
        it { expect(parsed_results.get("@type")).to be_nil }
        it { expect(parsed_results.get("parsed_json_field")).to be_nil }
        it { expect(parsed_results.get("parsed_json_field_name")).to be_nil }

      end
    end

  end

  # -- special cases
  describe "mutates 'msg'" do

    context "when it contains unicode (null)" do
      when_parsing_log(
          "@index_type" => "app",
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"event_type\":\"LogMessage\",\"level\":\"info\",\"message_type\":\"OUT\"," +
              "\"msg\":\"\\u0000\\u0000Some Message\"," + # contains unicode \u0000
              "\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"APP\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        # message (unicode characters were removed)
        it { expect(parsed_results.get("@message")).to eq "Some Message" }

      end
    end

    context "when it contains unicode (new line)" do
      when_parsing_log(
          "@index_type" => "app",
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"event_type\":\"LogMessage\",\"level\":\"info\",\"message_type\":\"OUT\"," +
              "\"msg\":\"Some Message\\u2028New line\"," + # contains unicode \u2028
              "\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"APP\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        # message (unicode characters were replaced with \n)
        it { expect(parsed_results.get("@message")).to eq "Some Message
New line" }

      end
    end

  end

  describe "sets @type" do

    context "when event_type is missing" do
      when_parsing_log(
          "@index_type" => "app",
          # event_type property is missing from JSON
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"level\":\"info\",\"message_type\":\"OUT\",\"msg\":\"Some Message\",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"APP\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        it { expect(parsed_results.get("@type")).to eq "UnknownEvent" } # is set to default value

      end
    end

    context "when event_type is passed" do
      when_parsing_log(
          "@index_type" => "app",
          # event_type is passed
          "@message" => "{\"event_type\":\"some event type value\", \"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"level\":\"info\",\"message_type\":\"OUT\",\"msg\":\"Some Message\",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"APP\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        it { expect(parsed_results.get("@type")).to eq "some event type value" } # is set from event_type

      end
    end

  end

  describe "sets [@source][type] when event is" do

    context "LogMessage" do
      when_parsing_log( "@index_type" => "app",
                        "@message" => "{\"event_type\":\"LogMessage\", \"msg\":\"some message\"}" ) do

        it { expect(parsed_results.get("@source")["type"]).to eq "LOG" }
      end
    end

    context "Error" do
      when_parsing_log( "@index_type" => "app",
                        "@message" => "{\"event_type\":\"Error\", \"msg\":\"some message\"}" ) do

        it { expect(parsed_results.get("@source")["type"]).to eq "ERR" }
      end
    end

    context "ContainerMetric" do
      when_parsing_log( "@index_type" => "app",
                        "@message" => "{\"event_type\":\"ContainerMetric\", \"msg\":\"some message\"}" ) do

        it { expect(parsed_results.get("@source")["type"]).to eq "CONTAINER" }
      end
    end

    context "ValueMetric" do
      when_parsing_log( "@index_type" => "app",
                        "@message" => "{\"event_type\":\"ValueMetric\", \"msg\":\"some message\"}" ) do

        it { expect(parsed_results.get("@source")["type"]).to eq "METRIC" }
      end
    end

    context "CounterEvent" do
      when_parsing_log( "@index_type" => "app",
                        "@message" => "{\"event_type\":\"CounterEvent\", \"msg\":\"some message\"}" ) do

        it { expect(parsed_results.get("@source")["type"]).to eq "COUNT" }
      end
    end

    context "HttpStartStop" do
      when_parsing_log( "@index_type" => "app",
                        "@message" => "{\"event_type\":\"HttpStartStop\", \"msg\":\"some message\"}" ) do

        it { expect(parsed_results.get("@source")["type"]).to eq "HTTP" }
      end
    end

    context "Unknown" do
      when_parsing_log( "@index_type" => "app",
                        "@message" => "{\"event_type\":\"Some unknown event type\", \"msg\":\"some message\"}" ) do

        it { expect(parsed_results.get("@source")["type"]).to eq "NA" }
      end
    end

  end

  describe "sets index name" do

    context "when no cf_org_name" do
      when_parsing_log(
          "@index_type" => "app",
          "@metadata" => {"index" => "app"},
          # cf_org_name property is missing from JSON
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"event_type\":\"LogMessage\",\"level\":\"info\",\"message_type\":\"OUT\",\"msg\":\"Some Message\",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"APP\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        # index name doesn't include neither org nor space
        it { expect(parsed_results.get("@cf")["org"]).to be_nil }
        it { expect(parsed_results.get("@metadata")["index"]).to eq "app" }

      end
    end

    context "when no cf_space_name" do
      when_parsing_log(
          "@index_type" => "app",
          "@metadata" => {"index" => "app"},
          # cf_space_name property is missing from JSON
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"event_type\":\"LogMessage\",\"level\":\"info\",\"message_type\":\"OUT\",\"msg\":\"Some Message\",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"APP\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        # index name includes org
        it { expect(parsed_results.get("@cf")["space"]).to be_nil }
        it { expect(parsed_results.get("@metadata")["index"]).to eq "app-admin" }

      end
    end

  end

end
