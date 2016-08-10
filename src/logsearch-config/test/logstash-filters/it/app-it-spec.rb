# encoding: utf-8
require 'test/logstash-filters/filter_test_helpers'
require 'test/logstash-filters/it_app_helper' # app it util

describe "App logs IT" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("target/logstash-filters-default.conf")} # NOTE: we use already built config here
      }
    CONFIG

  end

  # init app event (dummy)
  app_event_dummy = {"@type" => "syslog",
               "syslog_program" => "doppler",
               "syslog_pri" => "6",
               "syslog_severity_code" => 3,
               "host" => "bed08922-4734-4d62-9eba-3291aed1b8ce",
               "@message" => "Dummy message"}

  describe "checks all fields" do

    describe "when event is LogMessage & APP" do
      # NOTE: below tests are pretty the same but sample message is different
      # in case of Diego CF and Dea.

      describe "with Dea CF" do

        builder = MessagePayloadBuilder.new
            .origin("dea_logging_agent") # dea
            .job("runner_z1") # dea job
            .event_type("LogMessage")
            .source_type("App") # NOTE: Dea sets 'App' source_type as lowercase
            .level("info")

        context "(unknown msg format)" do

          app_message_payload = builder.clone
                                .msg("Some text msg") # unknown msg format
                                .build
          sample_event = app_event_dummy.clone
          sample_event["@message"] = construct_app_message(app_message_payload)

          when_parsing_log(sample_event) do
            verify_fields(app_message_payload.origin, app_message_payload.job,
                          app_message_payload.event_type, "APP", "INFO", "Some text msg")

            # verify format-specific fields
            it { expect(subject["tags"]).to include "unknown_msg_format" }
          end
        end

        context "(JSON msg)" do

          app_message_payload = builder.clone
                                    .msg("{\\\"timestamp\\\":\\\"2016-07-15 13:20:16.954\\\"," +
                                             "\\\"level\\\":\\\"ERROR\\\"," +
                                             "\\\"thread\\\":\\\"main\\\",\\\"logger\\\":\\\"com.abc.LogGenerator\\\"," +
                                             "\\\"message\\\":\\\"Some json msg\\\"}") # JSON msg
                                    .build
          sample_event = app_event_dummy.clone
          sample_event["@message"] = construct_app_message(app_message_payload)

          when_parsing_log(sample_event) do
            verify_fields(app_message_payload.origin, app_message_payload.job,
                          app_message_payload.event_type, "APP", "ERROR", "Some json msg")

            # verify format-specific fields
            it { expect(subject["tags"]).to include "log" }
            it { expect(subject["tags"]).not_to include "unknown_msg_format" }

            it { expect(subject["log"]["timestamp"]).to eq "2016-07-15 13:20:16.954" }
            it { expect(subject["log"]["thread"]).to eq "main" }
            it { expect(subject["log"]["logger"]).to eq "com.abc.LogGenerator" }
          end
        end

        context "([CONTAINER] log)" do
          app_message_payload = builder.clone
                                .msg("[CONTAINER] org.apache.catalina.startup.Catalina    DEBUG    Server startup in 9775 ms")
                                .build # [CONTAINER] msg
          sample_event = app_event_dummy.clone
          sample_event["@message"] = construct_app_message(app_message_payload)

          when_parsing_log(sample_event) do
            verify_fields(app_message_payload.origin, app_message_payload.job,
                          app_message_payload.event_type, "APP", "DEBUG", "Server startup in 9775 ms")

            # verify format-specific fields
            it { expect(subject["tags"]).to_not include "unknown_msg_format" }
            it { expect(subject["log"]["logger"]).to eq "[CONTAINER] org.apache.catalina.startup.Catalina" }
          end
        end

        context "(Logback status log)" do
          app_message_payload = builder.clone
                                .msg("16:41:17,033 |-DEBUG in ch.qos.logback.classic.joran.action.RootLoggerAction - Setting level of ROOT logger to WARN")
                                .build # Logback status msg
          sample_event = app_event_dummy.clone
          sample_event["@message"] = construct_app_message(app_message_payload)

          when_parsing_log(sample_event) do
            verify_fields(app_message_payload.origin, app_message_payload.job,
                          app_message_payload.event_type, "APP", "DEBUG", "Setting level of ROOT logger to WARN")

            # verify format-specific fields
            it { expect(subject["tags"]).to_not include "unknown_msg_format" }
            it { expect(subject["log"]["logger"]).to eq "ch.qos.logback.classic.joran.action.RootLoggerAction" }
          end
        end

      end

      describe "with Diego CF" do

        builder = MessagePayloadBuilder.new
                      .origin("rep") # diego
                      .job("cell_z1") # diego job
                      .event_type("LogMessage")
                      .source_type("APP") # NOTE: Diego sets 'APP' source_type as uppercase
                      .level("info")

        context "(unknown msg format)" do

          app_message_payload = builder.clone
                                    .msg("Some text msg") # unknown msg format
                                    .build
          sample_event = app_event_dummy.clone
          sample_event["@message"] = construct_app_message(app_message_payload)

          when_parsing_log(sample_event) do
            verify_fields(app_message_payload.origin, app_message_payload.job,
                          app_message_payload.event_type, "APP", "INFO", "Some text msg")

            # verify format-specific fields
            it { expect(subject["tags"]).to include "unknown_msg_format" }
          end
        end

        context "(JSON msg)" do

          app_message_payload = builder.clone
                                    .msg("{\\\"timestamp\\\":\\\"2016-07-15 13:20:16.954\\\"," +
                                             "\\\"level\\\":\\\"ERROR\\\"," +
                                             "\\\"thread\\\":\\\"main\\\",\\\"logger\\\":\\\"com.abc.LogGenerator\\\"," +
                                             "\\\"message\\\":\\\"Some json msg\\\"}") # JSON msg
                                    .build
          sample_event = app_event_dummy.clone
          sample_event["@message"] = construct_app_message(app_message_payload)

          when_parsing_log(sample_event) do
            verify_fields(app_message_payload.origin, app_message_payload.job,
                          app_message_payload.event_type, "APP", "ERROR", "Some json msg")

            # verify format-specific fields
            it { expect(subject["tags"]).to include "log" }
            it { expect(subject["tags"]).not_to include "unknown_msg_format" }

            it { expect(subject["log"]["timestamp"]).to eq "2016-07-15 13:20:16.954" }
            it { expect(subject["log"]["thread"]).to eq "main" }
            it { expect(subject["log"]["logger"]).to eq "com.abc.LogGenerator" }
          end
        end

        context "([CONTAINER] log)" do
          app_message_payload = builder.clone
                                    .msg("[CONTAINER] org.apache.catalina.startup.Catalina    DEBUG    Server startup in 9775 ms")
                                    .build # [CONTAINER] msg
          sample_event = app_event_dummy.clone
          sample_event["@message"] = construct_app_message(app_message_payload)

          when_parsing_log(sample_event) do
            verify_fields(app_message_payload.origin, app_message_payload.job,
                          app_message_payload.event_type, "APP", "DEBUG", "Server startup in 9775 ms")

            # verify format-specific fields
            it { expect(subject["tags"]).to_not include "unknown_msg_format" }
            it { expect(subject["log"]["logger"]).to eq "[CONTAINER] org.apache.catalina.startup.Catalina" }
          end
        end

        context "(Logback status log)" do
          app_message_payload = builder.clone
                                    .msg("16:41:17,033 |-DEBUG in ch.qos.logback.classic.joran.action.RootLoggerAction - Setting level of ROOT logger to WARN")
                                    .build # Logback status msg
          sample_event = app_event_dummy.clone
          sample_event["@message"] = construct_app_message(app_message_payload)

          when_parsing_log(sample_event) do
            verify_fields(app_message_payload.origin, app_message_payload.job,
                          app_message_payload.event_type, "APP", "DEBUG", "Setting level of ROOT logger to WARN")

            # verify format-specific fields
            it { expect(subject["tags"]).to_not include "unknown_msg_format" }
            it { expect(subject["log"]["logger"]).to eq "ch.qos.logback.classic.joran.action.RootLoggerAction" }
          end
        end

      end
    end

  end

  describe "checks drop useless event" do

    builder = MessagePayloadBuilder.new
                  .origin("rep")
                  .job("cell_z1")
                  .event_type("LogMessage")
                  .source_type("APP")
                  .level("info")


    context "when event is LogMessage & APP (drop)" do

      app_message_payload = builder.clone
                                .event_type("LogMessage") # LogMessage
                                .source_type("APP") # APP
                                .msg("   ") # useless
                                .build
      sample_event = app_event_dummy.clone
      sample_event["@message"] = construct_app_message(app_message_payload)

      when_parsing_log(sample_event) do
        it { expect(subject).to be_nil } # drop event
      end
    end

    context "when event is NOT LogMessage" do

      app_message_payload = builder.clone
                                .event_type("SomeOtherEvent") # any other but not LogMessage
                                .source_type("ANY") # any source
                                .msg("   ") # useless
                                .build
      sample_event = app_event_dummy.clone
      sample_event["@message"] = construct_app_message(app_message_payload)

      when_parsing_log(sample_event) do
        it { expect(subject).not_to be_nil } # keep event
      end
    end

  end

end
