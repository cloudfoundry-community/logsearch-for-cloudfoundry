# encoding: utf-8

class MessagePayload
  attr_accessor :deployment, :job, :message_text
end

class MessagePayloadBuilder
  attr_accessor :message_payload

  def initialize
    @message_payload = MessagePayload.new
  end

  def build
    @message_payload
  end

  def job(job)
    @message_payload.job = job
    self
  end

  def deployment(deployment)
    @message_payload.deployment = deployment
    self
  end

  def message_text(message_text)
    @message_payload.message_text = message_text
    self
  end
end

module Helpers
  module PlatformHelper
    def construct_cf_message__metronagent_format (message_payload)
      '[job='+ message_payload.job + ' index=5abc6def7ghi]  ' + message_payload.message_text
    end

    def construct_cf_message__syslogrelease_format (message_payload)
      '[bosh instance='+ message_payload.deployment + '/' + message_payload.job + '/5abc6def7ghi]  ' + message_payload.message_text
    end

    # -- Verify methods --
    def verify_platform_cf_fields__metronagent_format (expected_shipper, expected_component, expected_job,
                                                       expected_type, expected_tags,
                                                       expected_message, expected_level)

      verify_platform_cf_fields(expected_shipper, expected_job, expected_component, expected_type, expected_tags,
                                expected_message, expected_level)

      it { expect(parsed_results.get("@source")["deployment"]).to be_nil }


    end

    def verify_platform_cf_fields__syslogrelease_format (expected_shipper, expected_deployment, expected_component, expected_job,
                                                         expected_type, expected_tags,
                                                         expected_message, expected_level)

      verify_platform_cf_fields(expected_shipper, expected_job, expected_component, expected_type, expected_tags,
                                expected_message, expected_level);

      it { expect(parsed_results.get("@source")["deployment"]).to eq expected_deployment }


    end

    ## helper methods

    def verify_platform_cf_fields (expected_shipper, expected_job, expected_component,
                                   expected_type, expected_tags,
                                   expected_message, expected_level)

      verify_platform_fields(expected_shipper, expected_component, expected_type, expected_tags,
                             expected_message, expected_level)

      # verify CF format parsing
      it { expect(parsed_results.get("tags")).not_to include "fail/cloudfoundry/platform/grok" }
      it { expect(parsed_results.get("@source")["type"]).to eq "cf" }
      it { expect(parsed_results.get("@source")["job"]).to eq expected_job }
      it { expect(parsed_results.get("@source")["job_index"]).to eq "5abc6def7ghi" }
    end

    def verify_platform_fields (expected_shipper, expected_component, expected_type, expected_tags,
                                expected_message, expected_level)

      # fields
      it { expect(parsed_results.get("@message")).to eq expected_message }
      it { expect(parsed_results.get("@level")).to eq expected_level }

      it { expect(parsed_results.get("@index_type")).to eq "platform" }
      it { expect(parsed_results.get("@metadata")["index"]).to eq "platform" }
      it { expect(parsed_results.get("@input")).to eq "relp" }
      it { expect(parsed_results.get("@shipper")["priority"]).to eq "14" }
      it { expect(parsed_results.get("@shipper")["name"]).to eq expected_shipper }
      it { expect(parsed_results.get("@source")["host"]).to eq "192.168.111.24" }
      it { expect(parsed_results.get("@source")["component"]).to eq expected_component }
      it { expect(parsed_results.get("@type")).to eq expected_type }
      it { expect(parsed_results.get("tags")).to eq expected_tags }

      # verify no (default) dynamic JSON fields
      it { expect(parsed_results.get("parsed_json_field")).to be_nil }
      it { expect(parsed_results.get("parsed_json_field_name")).to be_nil }
    end
  end
end
