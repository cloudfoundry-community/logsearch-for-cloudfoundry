# encoding: utf-8
class MessagePayload
  attr_accessor :job, :message_text
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

  def message_text(message_text)
    @message_payload.message_text = message_text
    self
  end

end

def construct_platform_message (message_payload)
  '[job='+ message_payload.job + ' index=5]  ' + message_payload.message_text
end

def verify_platform_cf_fields (expected_shipper, expected_component, expected_job, expected_type, expected_tags, expected_message, expected_level)

  verify_platform_fields(expected_shipper, expected_component, expected_type, expected_tags, expected_message, expected_level)

  # verify CF fields
  it { expect(subject["tags"]).not_to include "fail/cloudfoundry/platform/grok" }

  it { expect(subject["@source"]["job"]).to eq expected_job }
  it { expect(subject["@source"]["instance"]).to eq 5 }
  it { expect(subject["@source"]["name"]).to eq expected_job + "/5" }

end

def verify_platform_fields (expected_shipper, expected_component, expected_type, expected_tags, expected_message, expected_level)

  # fields
  it { expect(subject["@message"]).to eq expected_message }
  it { expect(subject["@level"]).to eq expected_level }

  it { expect(subject["@input"]).to eq "relp" }
  it { expect(subject["@shipper"]["priority"]).to eq "14" }
  it { expect(subject["@shipper"]["name"]).to eq expected_shipper }
  it { expect(subject["@source"]["host"]).to eq "192.168.111.24" }
  it { expect(subject["@source"]["component"]).to eq expected_component }
  it { expect(subject["@metadata"]["index"]).to eq "platform" }
  it { expect(subject["@type"]).to eq expected_type }
  it { expect(subject["tags"]).to eq expected_tags }

end