# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/filters/grok"
require 'tempfile'

describe LogStash::Filters::Grok do

  config <<-CONFIG
    filter {
      #{File.read("vendor/logsearch-boshrelease/logstash-filters-default.conf")} # This simulates the default parsing that logsearch v19+ does
      #{File.read("target/logstash-filters-default.conf")}
    }
  CONFIG

  describe "UAA Audit events" do

    describe "UserAuthenticationSuccess" do
      sample("@type" => "syslog", "@message" => %q{<14>2015-08-25T04:57:46.033329+00:00 10.0.16.19 vcap.uaa [job=uaa-partition-7c53ed3ae2e7f5543b91 index=0]  [2015-08-25 04:57:46.033] uaa - 4176 [http-bio-8080-exec-4] ....  INFO --- Audit: UserAuthenticationSuccess ('admin'): principal=f63e0165-b85a-40d3-9ef7-78c6698ccb2c, origin=[remoteAddress=52.19.1.74, clientId=cf], identityZoneId=[uaa]}) do
        puts subject.to_hash.to_yaml

        # insist { subject[""] } == ""
        insist { subject["@timestamp"] } == Time.iso8601("2015-08-25T04:57:46.033Z")
        insist { subject["@loglevel"] } == "INFO"

        insist { subject["uaa_timestamp"] }.nil?
        insist { subject["syslog_pri"] }.nil?

        insist { subject["@source"]["syslog_program"] } == "vcap.uaa"
        insist { subject["@source"]["host"] } == "10.0.16.19"
        insist { subject["@source"]["job"]["name"] } == "uaa-partition-7c53ed3ae2e7f5543b91"
        insist { subject["@source"]["job"]["index"] } == "0"

        insist { subject["pid"] } == 4176
        insist { subject["thread_name"] } == "http-bio-8080-exec-4"
        insist { subject["audit_event_type"] } == "UserAuthenticationSuccess"
        insist { subject["audit_event_data"] } == "admin"
        insist { subject["audit_event_principal"] } == "f63e0165-b85a-40d3-9ef7-78c6698ccb2c"
        insist { subject["audit_event_origin"] } == ["remoteAddress=52.19.1.74", "clientId=cf"]
        insist { subject["audit_event_identity_zone_id"] } == "uaa"
      end
    end

#<14>2015-08-25T04:57:46.144106+00:00 10.0.16.19 vcap.uaa [job=uaa-partition-7c53ed3ae2e7f5543b91 index=0]  [2015-08-25 04:57:46.143] uaa - 4176 [http-bio-8080-exec-4] ....  INFO --- Audit: TokenIssuedEvent ('["cloud_controller.admin","cloud_controller.write","doppler.firehose","openid","scim.read","cloud_controller.read","password.write","scim.write"]'): principal=f63e0165-b85a-40d3-9ef7-78c6698ccb2c, origin=[client=cf, user=admin], identityZoneId=[uaa]
  end
end
