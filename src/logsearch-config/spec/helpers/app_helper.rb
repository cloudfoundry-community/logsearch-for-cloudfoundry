# encoding: utf-8

## -- Setup methods
$app_event_dummy = {
    "@type" => "syslog",
    "syslog_program" => "doppler",
    "syslog_pri" => "6",
    "syslog_severity_code" => 3, # error
    "host" => "bed08922-4734-4d62-9eba-3291aed1b8ce",
    "@message" => "Dummy message"}

$envelope_fields = {
    "cf_origin" => "firehose",
    "deployment" => "cf-full",
    "ip" => "192.168.111.32",
    "job" => "runner_z1",
    "job_index" => "4abc5def",
    "origin" => "MetronAgent",
    "time" => "2016-08-16T22:46:24Z"
}

$app_data_fields = {
    "cf_app_id" => "31b928ee-4110-4e7b-996c-334c5d7ac2ac",
    "cf_app_name" => "loggenerator",
    "cf_org_id" => "9887ad0a-f9f7-449e-8982-76307bd17239",
    "cf_org_name" => "admin",
    "cf_space_id" => "59cf41f2-3a1d-42db-88e7-9540b02945e8",
    "cf_space_name" => "demo"
}
module Helpers
  module AppHelper


    ## -- Verification methods
    def verify_app_general_fields (metadata_index, type, source_type, message, level)


      # no app parsing error
      it "sets tags" do
        expect(parsed_results.get("tags")).not_to include "fail/cloudfoundry/app/json"
        expect(parsed_results.get("tags")).to include "app"
      end

      it { expect(parsed_results.get("@type")).to eq type }

      it { expect(parsed_results.get("@index_type")).to eq "app" }
      it { expect(parsed_results.get("@metadata")["index"]).to eq metadata_index }

      it { expect(parsed_results.get("@input")).to eq "syslog" }

      it { expect(parsed_results.get("@shipper")["priority"]).to eq "6" }
      it { expect(parsed_results.get("@shipper")["name"]).to eq "doppler_syslog" }

      it "sets @source fields" do
        expect(parsed_results.get("@source")["deployment"]).to eq "cf-full"
        expect(parsed_results.get("@source")["host"]).to eq "192.168.111.32"
        expect(parsed_results.get("@source")["job"]).to eq "runner_z1"
        expect(parsed_results.get("@source")["job_index"]).to eq "4abc5def"
        expect(parsed_results.get("@source")["component"]).to eq "MetronAgent"
        expect(parsed_results.get("@source")["type"]).to eq source_type
      end

      it { expect(parsed_results.get("@message")).to eq message }
      it { expect(parsed_results.get("@level")).to eq level }

      # verify no (default) dynamic JSON fields
      it { expect(parsed_results.get("parsed_json_field")).to be_nil }
      it { expect(parsed_results.get("parsed_json_field_name")).to be_nil }

    end

    def verify_app_cf_fields (app_instance)

      it "sets @cf fields" do
        expect(parsed_results.get("@cf")["origin"]).to eq "firehose"
        expect(parsed_results.get("@cf")["app"]).to eq "loggenerator"
        expect(parsed_results.get("@cf")["app_id"]).to eq "31b928ee-4110-4e7b-996c-334c5d7ac2ac"
        expect(parsed_results.get("@cf")["app_instance"]).to eq app_instance
        expect(parsed_results.get("@cf")["space"]).to eq "demo"
        expect(parsed_results.get("@cf")["space_id"]).to eq "59cf41f2-3a1d-42db-88e7-9540b02945e8"
        expect(parsed_results.get("@cf")["org"]).to eq "admin"
        expect(parsed_results.get("@cf")["org_id"]).to eq "9887ad0a-f9f7-449e-8982-76307bd17239"
      end

    end

    ## -- Special cases
    def verify_parsing_logmessage_app_CF_versions(level, msg, expected_level, expected_message, &block)
      context "in (Diego CF)" do
        verify_parsing_logmessage_app(true, # Diego
                                      level, msg, expected_level, expected_message, &block)
      end

      context "in (Dea CF)" do
        verify_parsing_logmessage_app(false, # Dea
                                      level, msg, expected_level, expected_message, &block)
      end
    end

    def verify_parsing_logmessage_app(isDiego, level, msg, expected_level, expected_message, &block)
      sample_fields = {"source_type" => isDiego ? "APP" : "App", # Diego/Dea specific
                       "source_instance" => "99",
                       "message_type" => "OUT",
                       "timestamp" => 1471387745714800488,
                       "level" => level,
                       "msg" => "Dummy msg"}

      sample_fields["msg"] = msg

      sample_event = $app_event_dummy.clone
      sample_event["@message"] = construct_event("LogMessage", true, sample_fields)

      when_parsing_log(sample_event) do

        verify_app_general_fields("app-admin-demo", "LogMessage", "APP",
                                  expected_message, expected_level)

        verify_app_cf_fields(99)

        # verify event-specific fields
        it { expect(parsed_results.get("tags")).to include("logmessage", "logmessage-app") }
        it { expect(parsed_results.get("logmessage")["message_type"]).to eq "OUT" }

        # additional verifications
        describe("", &block)

      end
    end

    private
    def append_fields_from_hash(hash)
      result = ""
      hash.each do |key, value|
        result += append_field(key, value)
      end
      result
    end

    def append_field(field_name, field_value)
      '"' + field_name + '":' + (field_value.is_a?(String) ?
                               '"' + field_value + '"' : field_value.to_s) + ','
    end

    def construct_event(event_type, is_include_app_data, event_fields_hash)

      # envelope
      result = '{' +
          append_field("event_type", event_type) +
          append_fields_from_hash($envelope_fields)

      # app data
      if is_include_app_data
        result += append_fields_from_hash($app_data_fields)
      end

      # event fields
      result += append_fields_from_hash(event_fields_hash)

      result = result[0...-1] + '}' # cut last comma (,)

    end
  end
end

