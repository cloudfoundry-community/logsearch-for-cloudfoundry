# encoding: utf-8
require 'test/filter_test_helpers'

describe "app.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/app.conf")}
      }
    CONFIG
  end

  # -- test snippet's 'if' condition --
  describe "#if" do

    describe "passed" do
      context "when @type = relp" do
        when_parsing_log(
            "@type" => "relp", # good value
            "syslog_program" => "doppler", # good value
            "@message" => "Some invalid JSON here"
        ) do

          # app tag set => 'if' succeeded
          it { expect(subject["tags"]).to include "fail/cloudfoundry/app/json" }

        end
      end

      context "when @type = syslog" do
        when_parsing_log(
            "@type" => "syslog", # good value
            "syslog_program" => "doppler", # good value
            "@message" => "Some invalid JSON here"
        ) do

          # app tag set => 'if' succeeded
          it { expect(subject["tags"]).to include "fail/cloudfoundry/app/json" }

        end
      end
    end

    describe "failed" do
      context "when bad @type" do
        when_parsing_log(
            "@type" => "Some type", # bad value
            "syslog_program" => "doppler",
            "@message" => "Some message here"
        ) do

          # no tags set => 'if' failed
          it { expect(subject["tags"]).to be_nil }

        end
      end

      context "when bad syslog_program" do
        when_parsing_log(
            "@type" => "relp",
            "syslog_program" => "some-value-but-not-doppler", # bad value
            "@message" => "Some invalid JSON here"
        ) do

          # no tags set => 'if' failed
          it { expect(subject["tags"]).to be_nil }

        end
      end
    end

  end

  # -- test json success and failure cases (verify all fields) --
  describe "#json" do

    context "succeeded" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "doppler",
          # valid JSON
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"event_type\":\"LogMessage\",\"level\":\"info\",\"message_type\":\"OUT\",\"msg\":\"Some Message\",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"APP\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        # no parsing errors
        it { expect(subject["tags"]).not_to include "fail/cloudfoundry/app/json" }

        # fields
        it "should set mandatory fields" do
          expect(subject["@message"]).to eq "Some Message"
          expect(subject["@level"]).to eq "info"
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
          expect(subject["app"]).to be_nil # cleaned up
        end

        it "should set general fields" do
          expect(subject["@source"]["component"]).to eq "APP"
          expect(subject["@metadata"]["index"]).to eq "app-admin-demo"
          expect(subject["@type"]).to eq "LogMessage"
          expect(subject["tags"]).to include "app"
        end

      end
    end

    context "failed" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "doppler",
          # invalid JSON
          "@message" => "Some message that is invalid json"
      ) do

        # get parsing error
        it { expect(subject["tags"]).to include "fail/cloudfoundry/app/json" }

        # no fields set
        it "shouldn't set JSON fields" do
          expect(subject["@source"]).to be_nil
          expect(subject["@message"]).to eq "Some message that is invalid json" # the same as before parsing
        end

        it "shouldn't set general fields" do
          expect(subject["@metadata"]["index"]).to be_nil # @metadata is system field so it exists even if not set ..
          # ..(that's why we should check exactly @metadata.index for nil)

          expect(subject["@type"]).to eq "relp"
          expect(subject["tags"]).not_to include "app"
        end

      end
    end

  end

  # -- test special cases (verify specific fields) --
  describe "mutates 'msg'" do

    context "when it contains unicode (null)" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "doppler",
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"event_type\":\"LogMessage\",\"level\":\"info\",\"message_type\":\"OUT\"," +
              "\"msg\":\"\\u0000\\u0000Some Message\"," + # contains unicode \u0000
              "\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"APP\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        # message (unicode characters were removed)
        it { expect(subject["@message"]).to eq "Some Message" }

      end
    end

    context "when it contains unicode (new line)" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "doppler",
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"event_type\":\"LogMessage\",\"level\":\"info\",\"message_type\":\"OUT\"," +
              "\"msg\":\"Some Message\\u2028New line\"," + # contains unicode \u2028
              "\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"APP\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        # message (unicode characters were replaced with \n)
        it { expect(subject["@message"]).to eq "Some Message
New line" }

      end
    end

  end

  describe "drops event" do

    context "when 'msg' is useless (empty)" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "doppler",
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"event_type\":\"LogMessage\",\"level\":\"info\",\"message_type\":\"OUT\"," +
              "\"msg\":\"\"" + # empty msg
              ",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"APP\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        # useless event was dropped
        it { expect(subject).to be_nil }

      end
    end

    context "when 'msg' is useless (blank)" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "doppler",
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"event_type\":\"LogMessage\",\"level\":\"info\",\"message_type\":\"OUT\"," +
              "\"msg\":\"    \"," + # blank msg
              "\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"APP\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        # useless event was dropped
        it { expect(subject).to be_nil }

      end
    end

  end

  describe "sets @type" do

    context "when event_type is missing" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "doppler",
          # event_type property is missing from JSON
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"level\":\"info\",\"message_type\":\"OUT\",\"msg\":\"Some Message\",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"APP\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        it { expect(subject["@type"]).to eq "LogMessage" } # is set to default value

      end
    end

    context "when event_type is passed" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "doppler",
          # event_type is passed
          "@message" => "{\"event_type\":\"some event type value\", \"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"level\":\"info\",\"message_type\":\"OUT\",\"msg\":\"Some Message\",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"APP\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        it { expect(subject["@type"]).to eq "some event type value" } # is set from event_type

      end
    end

  end

  describe "uppercases [@source][component]" do
    when_parsing_log(
        "@type" => "relp",
        "syslog_program" => "doppler",
        "@message" => "{\"source_type\":\"APP\"," + # lowercase source_type
            " \"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"level\":\"info\",\"message_type\":\"OUT\",\"msg\":\"Some Message\",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
    ) do

      it { expect(subject["@source"]["component"]).to eq "APP" } # uppercase

    end
  end

  describe "sets index name" do

    context "when no cf_org_name" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "doppler",
          # cf_org_name property is missing from JSON
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"cf_space_name\":\"demo\",\"event_type\":\"LogMessage\",\"level\":\"info\",\"message_type\":\"OUT\",\"msg\":\"Some Message\",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"APP\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        # index name doesn't include neither org nor space
        it { expect(subject["@source"]["org"]).to be_nil }
        it{ expect(subject["@metadata"]["index"]).to eq "app" }

      end
    end

    context "when no cf_space_name" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "doppler",
          # cf_space_name property is missing from JSON
          "@message" => "{\"cf_app_id\":\"31b928ee-4110-4e7b-996c-334c5d7ac2ac\",\"cf_app_name\":\"loggenerator\",\"cf_org_id\":\"9887ad0a-f9f7-449e-8982-76307bd17239\",\"cf_org_name\":\"admin\",\"cf_origin\":\"firehose\",\"cf_space_id\":\"59cf41f2-3a1d-42db-88e7-9540b02945e8\",\"event_type\":\"LogMessage\",\"level\":\"info\",\"message_type\":\"OUT\",\"msg\":\"Some Message\",\"origin\":\"dea_logging_agent\",\"source_instance\":\"0\",\"source_type\":\"APP\",\"time\":\"2016-07-08T10:00:40Z\",\"timestamp\":1467972040073786262}"
      ) do

        # index name includes org
        it { expect(subject["@source"]["space"]).to be_nil }
        it{ expect(subject["@metadata"]["index"]).to eq "app-admin" }

      end
    end

  end

end
