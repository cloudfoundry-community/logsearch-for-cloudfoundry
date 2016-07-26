# encoding: utf-8
class MessagePayload
  attr_accessor :origin, :job, :event_type, :source_type, :msg, :level
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

  def origin(origin)
    @message_payload.origin = origin
    self
  end

  def event_type(event_type)
    @message_payload.event_type = event_type
    self
  end

  def source_type(source_type)
    @message_payload.source_type = source_type
    self
  end

  def msg(msg)
    @message_payload.msg = msg
    self
  end

  def level(level)
    @message_payload.level = level
    self
  end
end

def construct_app_message (message_payload)
  '{
    "cf_app_id":"31b928ee-4110-4e7b-996c-334c5d7ac2ac", "cf_app_name":"loggenerator",
    "cf_org_id":"9887ad0a-f9f7-449e-8982-76307bd17239", "cf_org_name":"admin",
    "cf_origin":"firehose",
    "cf_space_id":"59cf41f2-3a1d-42db-88e7-9540b02945e8","cf_space_name":"demo",
    "deployment":"cf-full",
    "event_type":"' + message_payload.event_type + '",
    "index":"0","ip":"192.168.111.35","job":"' + message_payload.job + '",
    "level":"info",
    "message_type":"OUT",
    "msg":"' + message_payload.msg + '" ,
    "origin":"' + message_payload.origin + '" ,
    "source_instance":"0",
    "source_type":"' + message_payload.source_type + '",
    "time":"2016-07-08T10:00:40Z", "timestamp":1467972040073786262 }'
end

def verify_fields (expected_origin, expected_job, expected_type, expected_source, expected_level, expected_message)

  # no parsing errors
  it { expect(subject["@tags"]).not_to include "fail/cloudfoundry/app/json" }

  # fields
  it "should set common fields" do
    expect(subject["@input"]).to eq "syslog"
    expect(subject["@shipper"]["priority"]).to eq "6"
    expect(subject["@shipper"]["name"]).to eq "doppler_syslog"
    expect(subject["@source"]["host"]).to eq "192.168.111.35"
    expect(subject["@source"]["name"]).to eq (expected_job + "/0")
    expect(subject["@source"]["instance"]).to eq 0
    expect(subject["@source"]["deployment"]).to eq "cf-full"
    expect(subject["@source"]["job"]).to eq expected_job

    expect(subject["@metadata"]["index"]).to eq "app-admin-demo"
  end

  it "should override common fields" do
    expect(subject["@source"]["component"]).to eq expected_source
    expect(subject["@type"]).to eq expected_type
    expect(subject["@tags"]).to include "app"
  end

  it "should set app specific fields" do
    expect(subject["@source"]["app"]).to eq "loggenerator"
    expect(subject["@source"]["app_id"]).to eq "31b928ee-4110-4e7b-996c-334c5d7ac2ac"
    expect(subject["@source"]["space"]).to eq "demo"
    expect(subject["@source"]["space_id"]).to eq "59cf41f2-3a1d-42db-88e7-9540b02945e8"
    expect(subject["@source"]["org"]).to eq "admin"
    expect(subject["@source"]["org_id"]).to eq "9887ad0a-f9f7-449e-8982-76307bd17239"
    expect(subject["@source"]["origin"]).to eq expected_origin
    expect(subject["@source"]["message_type"]).to eq "OUT"
  end

  it "should set mandatory fields" do
    expect(subject["@message"]).to eq expected_message
    expect(subject["@level"]).to eq expected_level
  end

end