# encoding: utf-8
require 'test/filter_test_helpers'
require 'tempfile'

describe "UAA Audit Spec Logs" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/uaa.conf")}
      }
    CONFIG
  end

  describe "UAA Audit events" do

    describe "common fields" do
      when_parsing_log(
        "@type" => "syslog",
        "@message" => %q{<14>2015-08-25T04:57:46.033329+00:00 10.0.16.19 vcap.uaa [job=uaa-partition-7c53ed3ae2e7f5543b91 index=0]  [2015-08-25 04:57:46.033] uaa - 4176 [http-bio-8080-exec-4] ....  INFO --- Audit: UserAuthenticationSuccess ('admin'): principal=f63e0165-b85a-40d3-9ef7-78c6698ccb2c, origin=[remoteAddress=52.19.1.74, clientId=cf], identityZoneId=[uaa]}
      ) do

        it "parses log" do

          ap subject
          expect(subject["@type"]).to eq "uaa-audit"
          expect(subject["tags"]).to include("uaa-audit")
          expect(subject["tags"]).not_to include("fail/cloudfoundry/uaa-audit")

          expect(subject["@timestamp"]).to eq Time.iso8601("2015-08-25T03:57:46.033Z")
          expect(subject["@level"]).to eq "INFO"

          expect(subject["uaa_timestamp"]).nil?

          expect(subject["syslog_pri"]).nil?
          expect(subject["syslog_facility"]).nil?
          expect(subject["syslog_facility_code"]).nil?
          expect(subject["syslog_severity"]).nil?
          expect(subject["syslog_severity_code"]).nil?
          expect(subject["@message"]).nil?
          expect(subject["@source"]["component"]).to eq "UAA"
          expect(subject["@source"]["name"]).to eq "uaa-partition-7c53ed3ae2e7f5543b91/0"
          expect(subject["@source"]["instance"]).to eq 0
        end
      end
    end

    describe "UserAuthenticationSuccess" do
      when_parsing_log(
        "@type" => "syslog",
        "@message" => %q{<14>2015-08-25T04:57:46.033329+00:00 10.0.16.19 vcap.uaa [job=uaa-partition-7c53ed3ae2e7f5543b91 index=0]  [2015-08-25 04:57:46.033] uaa - 4176 [http-bio-8080-exec-4] ....  INFO --- Audit: UserAuthenticationSuccess ('admin'): principal=f63e0165-b85a-40d3-9ef7-78c6698ccb2c, origin=[remoteAddress=52.19.1.74, clientId=cf], identityZoneId=[uaa]}
      ) do

        it "parses log" do

          expect(subject["tags"]).not_to include("fail/cloudfoundry/uaa-audit")

          expect(subject["@timestamp"]).to eq Time.iso8601("2015-08-25T03:57:46.033Z")
          expect(subject["@level"]).to eq "INFO"

          expect(subject["UAA"]["pid"]).to eq 4176
          expect(subject["UAA"]["thread_name"]).to eq "http-bio-8080-exec-4"
          expect(subject["UAA"]["type"]).to eq "UserAuthenticationSuccess"
          expect(subject["UAA"]["data"]).to eq "admin"
          expect(subject["UAA"]["principal"]).to eq "f63e0165-b85a-40d3-9ef7-78c6698ccb2c"
          expect(subject["UAA"]["origin"]).to eq ["remoteAddress=52.19.1.74", "clientId=cf"]
          expect(subject["UAA"]["identity_zone_id"]).to eq "uaa"
        end
      end
    end

    describe "TokenIssuedEvent" do
      when_parsing_log(
        "@type" => "syslog",
        "@message" => %q{<14>2015-08-25T04:57:46.144106+00:00 10.0.16.19 vcap.uaa [job=uaa-partition-7c53ed3ae2e7f5543b91 index=0]  [2015-08-25 04:57:46.143] uaa - 4176 [http-bio-8080-exec-4] ....  INFO --- Audit: TokenIssuedEvent ('["cloud_controller.admin","cloud_controller.write","doppler.firehose","openid","scim.read","cloud_controller.read","password.write","scim.write"]'): principal=f63e0165-b85a-40d3-9ef7-78c6698ccb2c, origin=[client=cf, user=admin], identityZoneId=[uaa]}
      ) do

        it "parses log" do

          expect(subject["tags"]).not_to include("fail/cloudfoundry/uaa-audit")

          expect(subject["@timestamp"]).to eq Time.iso8601("2015-08-25T03:57:46.143Z")
          expect(subject["@level"]).to eq "INFO"

          expect(subject["UAA"]["pid"]).to eq 4176
          expect(subject["UAA"]["thread_name"]).to eq "http-bio-8080-exec-4"
          expect(subject["UAA"]["type"]).to eq "TokenIssuedEvent"
          expect(subject["UAA"]["data"]).to eq '["cloud_controller.admin","cloud_controller.write","doppler.firehose","openid","scim.read","cloud_controller.read","password.write","scim.write"]'
          expect(subject["UAA"]["principal"]).to eq "f63e0165-b85a-40d3-9ef7-78c6698ccb2c"
          expect(subject["UAA"]["origin"]).to eq ["client=cf", "user=admin"]
          expect(subject["UAA"]["identity_zone_id"]).to eq "uaa"
        end
      end
    end

    describe "UserNotFound" do
      when_parsing_log(
        "@type" => "syslog",
        "@message" => %q{<14>2015-08-26T06:44:05.744726+00:00 10.0.16.19 vcap.uaa [job=uaa-partition-7c53ed3ae2e7f5543b91 index=0]  [2015-08-26 06:44:05.744] uaa - 4159 [http-bio-8080-exec-7] ....  INFO --- Audit: UserNotFound (''): principal=1S0lQEF695QPAYN7mnBqQ0HpJVc=, origin=[remoteAddress=80.229.7.108], identityZoneId=[uaa]}
      ) do

        it "parses log" do
          expect(subject["tags"]).not_to include("fail/cloudfoundry/uaa-audit")

          expect(subject["@timestamp"]).to eq Time.iso8601("2015-08-26T05:44:05.744Z")
          expect(subject["@level"]).to eq "INFO"

          expect(subject["UAA"]["pid"]).to eq 4159
          expect(subject["UAA"]["thread_name"]).to eq "http-bio-8080-exec-7"
          expect(subject["UAA"]["type"]).to eq "UserNotFound"
          expect(subject["UAA"]["data"]).nil?
          expect(subject["UAA"]["principal"]).to eq "1S0lQEF695QPAYN7mnBqQ0HpJVc="
          expect(subject["UAA"]["origin"]).to eq ["remoteAddress=80.229.7.108"]
          expect(subject["UAA"]["identity_zone_id"]).to eq "uaa"
        end
      end
    end

    describe "extract remoteAddress" do
      when_parsing_log(
        "@type" => "syslog",
        "@message" => %q{<14>2015-08-28T05:57:02.867064+00:00 10.0.16.19 vcap.uaa [job=uaa-partition-7c53ed3ae2e7f5543b91 index=0]  [2015-08-28 05:57:02.866] uaa - 4181 [http-bio-8080-exec-10] ....  INFO --- Audit: ClientAuthenticationSuccess ('Client authentication success'): principal=null, origin=[remoteAddress=52.19.1.74], identityZoneId=[uaa]}
       ) do

        it "parses log" do
          expect(subject["tags"]).not_to include("fail/cloudfoundry/uaa-audit")

          expect(subject["UAA"]["remote_address"]).to eq "52.19.1.74"
          expect(subject["geoip"]["ip"]).to eq "52.19.1.74"
        end
      end

      when_parsing_log(
        "@type" => "syslog",
        "@message" => %q{<14>2015-08-26T06:44:05.744726+00:00 10.0.16.19 vcap.uaa [job=uaa-partition-7c53ed3ae2e7f5543b91 index=0]  [2015-08-26 06:44:05.744] uaa - 4159 [http-bio-8080-exec-7] ....  INFO --- Audit: UserNotFound (''): principal=1S0lQEF695QPAYN7mnBqQ0HpJVc=, origin=[remoteAddress=80.229.7.108], identityZoneId=[uaa]}
      ) do

	#puts subject.to_hash.to_yaml

        it "parses log" do
          expect(subject["tags"]).not_to include("fail/cloudfoundry/uaa-audit")

          expect(subject["UAA"]["remote_address"]).to eq "80.229.7.108"
          expect(subject["geoip"]["ip"]).to eq "80.229.7.108"
        end
      end

      when_parsing_log(
        "@type" => "syslog",
        "@message" => %q{<14>2015-08-28T06:58:51.869603+00:00 10.0.16.19 vcap.uaa [job=uaa-partition-7c53ed3ae2e7f5543b91 index=0]  [2015-08-28 06:58:51.869] uaa - 4181 [http-bio-8080-exec-7] ....  INFO --- Audit: PrincipalAuthenticationFailure ('null'): principal=adas, origin=[52.17.158.141], identityZoneId=[uaa]}
      ) do

	#puts subject.to_hash.to_yaml

        it "parses log" do
          expect(subject["tags"]).not_to include("fail/cloudfoundry/uaa-audit")

          expect(subject["UAA"]["remote_address"]).to eq "52.17.158.141"
          expect(subject["geoip"]["ip"]).to eq "52.17.158.141"
        end
      end
    end
  end
end
