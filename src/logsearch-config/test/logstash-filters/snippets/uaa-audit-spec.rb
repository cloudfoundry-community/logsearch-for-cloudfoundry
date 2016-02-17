# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/filters/grok"
require 'tempfile'

module Enumerable
  def does_not_include?(item)
    !include?(item)
  end
end

describe LogStash::Filters::Grok do

  config <<-CONFIG
    filter {
      #{File.read("vendor/logsearch-boshrelease/src/logsearch-config/target/logstash-filters-default.conf")}
      #{File.read("target/logstash-filters-default.conf")}
    }
  CONFIG

  describe "UAA Audit events" do

    describe "common fields" do
      sample("@type" => "syslog", "@message" => %q{<14>2015-08-25T04:57:46.033329+00:00 10.0.16.19 vcap.uaa [job=uaa-partition-7c53ed3ae2e7f5543b91 index=0]  [2015-08-25 04:57:46.033] uaa - 4176 [http-bio-8080-exec-4] ....  INFO --- Audit: UserAuthenticationSuccess ('admin'): principal=f63e0165-b85a-40d3-9ef7-78c6698ccb2c, origin=[remoteAddress=52.19.1.74, clientId=cf], identityZoneId=[uaa]}) do

        insist { subject["@metadata"]["type"] } == "uaa-audit"
        insist { subject["tags"] }.include?("uaa-audit")
        insist { subject["tags"] }.does_not_include?("fail/cloudfoundry/uaa-audit")

        insist { subject["@timestamp"] } == Time.iso8601("2015-08-25T04:57:46.033Z")
        insist { subject["@level"] } == "INFO"

        insist { subject["uaa_timestamp"] }.nil?

        insist { subject["syslog_pri"] }.nil?
        insist { subject["syslog_facility"] }.nil?
        insist { subject["syslog_facility_code"] }.nil?
        insist { subject["syslog_severity"] }.nil?
        insist { subject["syslog_severity_code"] }.nil?
        insist { subject["@message"] }.nil?

        insist { subject["@source"]["component"] } == "UAA"
        insist { subject["@source"]["host"] } == "10.0.16.19"
        insist { subject["@source"]["name"] } == "uaa-partition-7c53ed3ae2e7f5543b91/0"
        insist { subject["@source"]["instance"] } == 0

      end
    end

    describe "UserAuthenticationSuccess" do
      sample("@type" => "syslog", "@message" => %q{<14>2015-08-25T04:57:46.033329+00:00 10.0.16.19 vcap.uaa [job=uaa-partition-7c53ed3ae2e7f5543b91 index=0]  [2015-08-25 04:57:46.033] uaa - 4176 [http-bio-8080-exec-4] ....  INFO --- Audit: UserAuthenticationSuccess ('admin'): principal=f63e0165-b85a-40d3-9ef7-78c6698ccb2c, origin=[remoteAddress=52.19.1.74, clientId=cf], identityZoneId=[uaa]}) do

        insist { subject["tags"] }.does_not_include?("fail/cloudfoundry/uaa-audit")

        insist { subject["@timestamp"] } == Time.iso8601("2015-08-25T04:57:46.033Z")
        insist { subject["@level"] } == "INFO"

        insist { subject["UAA"]["pid"] } == 4176
        insist { subject["UAA"]["thread_name"] } == "http-bio-8080-exec-4"
        insist { subject["UAA"]["type"] } == "UserAuthenticationSuccess"
        insist { subject["UAA"]["data"] } == "admin"
        insist { subject["UAA"]["principal"] } == "f63e0165-b85a-40d3-9ef7-78c6698ccb2c"
        insist { subject["UAA"]["origin"] } == ["remoteAddress=52.19.1.74", "clientId=cf"]
        insist { subject["UAA"]["identity_zone_id"] } == "uaa"
      end
    end

    describe "TokenIssuedEvent" do
      sample("@type" => "syslog", "@message" => %q{<14>2015-08-25T04:57:46.144106+00:00 10.0.16.19 vcap.uaa [job=uaa-partition-7c53ed3ae2e7f5543b91 index=0]  [2015-08-25 04:57:46.143] uaa - 4176 [http-bio-8080-exec-4] ....  INFO --- Audit: TokenIssuedEvent ('["cloud_controller.admin","cloud_controller.write","doppler.firehose","openid","scim.read","cloud_controller.read","password.write","scim.write"]'): principal=f63e0165-b85a-40d3-9ef7-78c6698ccb2c, origin=[client=cf, user=admin], identityZoneId=[uaa]}) do

        insist { subject["tags"] }.does_not_include?("fail/cloudfoundry/uaa-audit")

        insist { subject["@timestamp"] } == Time.iso8601("2015-08-25T04:57:46.143Z")
        insist { subject["@level"] } == "INFO"

        insist { subject["UAA"]["pid"] } == 4176
        insist { subject["UAA"]["thread_name"] } == "http-bio-8080-exec-4"
        insist { subject["UAA"]["type"] } == "TokenIssuedEvent"
        insist { subject["UAA"]["data"] } == '["cloud_controller.admin","cloud_controller.write","doppler.firehose","openid","scim.read","cloud_controller.read","password.write","scim.write"]'
        insist { subject["UAA"]["principal"] } == "f63e0165-b85a-40d3-9ef7-78c6698ccb2c"
        insist { subject["UAA"]["origin"] } == ["client=cf", "user=admin"]
        insist { subject["UAA"]["identity_zone_id"] } == "uaa"
      end
    end

    describe "UserNotFound" do
      sample("@type" => "syslog", "@message" => %q{<14>2015-08-26T06:44:05.744726+00:00 10.0.16.19 vcap.uaa [job=uaa-partition-7c53ed3ae2e7f5543b91 index=0]  [2015-08-26 06:44:05.744] uaa - 4159 [http-bio-8080-exec-7] ....  INFO --- Audit: UserNotFound (''): principal=1S0lQEF695QPAYN7mnBqQ0HpJVc=, origin=[remoteAddress=80.229.7.108], identityZoneId=[uaa]}) do

        insist { subject["tags"] }.does_not_include?("fail/cloudfoundry/uaa-audit")

        insist { subject["@timestamp"] } == Time.iso8601("2015-08-26T06:44:05.744Z")
        insist { subject["@level"] } == "INFO"

        insist { subject["UAA"]["pid"] } == 4159
        insist { subject["UAA"]["thread_name"] } == "http-bio-8080-exec-7"
        insist { subject["UAA"]["type"] } == "UserNotFound"
        insist { subject["UAA"]["data"] }.nil?
        insist { subject["UAA"]["principal"] } == "1S0lQEF695QPAYN7mnBqQ0HpJVc="
        insist { subject["UAA"]["origin"] } == ["remoteAddress=80.229.7.108"]
        insist { subject["UAA"]["identity_zone_id"] } == "uaa"
      end
    end

    describe "extract remoteAddress" do
      sample("@type" => "syslog", "@message" => %q{<14>2015-08-28T05:57:02.867064+00:00 10.0.16.19 vcap.uaa [job=uaa-partition-7c53ed3ae2e7f5543b91 index=0]  [2015-08-28 05:57:02.866] uaa - 4181 [http-bio-8080-exec-10] ....  INFO --- Audit: ClientAuthenticationSuccess ('Client authentication success'): principal=null, origin=[remoteAddress=52.19.1.74], identityZoneId=[uaa]}) do

        insist { subject["tags"] }.does_not_include?("fail/cloudfoundry/uaa-audit")

        insist { subject["UAA"]["remote_address"] } == "52.19.1.74"
        insist { subject["geoip"]["ip"] } == "52.19.1.74"
      end

      sample("@type" => "syslog", "@message" => %q{<14>2015-08-26T06:44:05.744726+00:00 10.0.16.19 vcap.uaa [job=uaa-partition-7c53ed3ae2e7f5543b91 index=0]  [2015-08-26 06:44:05.744] uaa - 4159 [http-bio-8080-exec-7] ....  INFO --- Audit: UserNotFound (''): principal=1S0lQEF695QPAYN7mnBqQ0HpJVc=, origin=[remoteAddress=80.229.7.108], identityZoneId=[uaa]}) do

	#puts subject.to_hash.to_yaml

        insist { subject["tags"] }.does_not_include?("fail/cloudfoundry/uaa-audit")

        insist { subject["UAA"]["remote_address"] } == "80.229.7.108"
        insist { subject["geoip"]["ip"] } == "80.229.7.108"
      end

      sample("@type" => "syslog", "@message" => %q{<14>2015-08-28T06:58:51.869603+00:00 10.0.16.19 vcap.uaa [job=uaa-partition-7c53ed3ae2e7f5543b91 index=0]  [2015-08-28 06:58:51.869] uaa - 4181 [http-bio-8080-exec-7] ....  INFO --- Audit: PrincipalAuthenticationFailure ('null'): principal=adas, origin=[52.17.158.141], identityZoneId=[uaa]}) do

	#puts subject.to_hash.to_yaml

        insist { subject["tags"] }.does_not_include?("fail/cloudfoundry/uaa-audit")

        insist { subject["UAA"]["remote_address"] } == "52.17.158.141"
        insist { subject["geoip"]["ip"] } == "52.17.158.141"
      end
   end

  end
end
