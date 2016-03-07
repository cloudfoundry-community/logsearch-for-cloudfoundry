# encoding: utf-8
require 'test/filter_test_helpers'

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
        "syslog_program" => "vcap.uaa",
        "@message" => "[2015-08-25 04:57:46.033] uaa - 4176 [http-bio-8080-exec-4] ....  INFO --- Audit: UserAuthenticationSuccess ('admin'): principal=f63e0165-b85a-40d3-9ef7-78c6698ccb2c, origin=[remoteAddress=52.19.1.74, clientId=cf], identityZoneId=[uaa]"
      ) do

        it "adds the uaa-audit tag" do
          expect(subject["tags"]).to include "uaa-audit"
        end

        it "sets @type to uaa-audit" do
          expect(subject["@type"]).to eq "uaa-audit"
        end

        it "sets @level to the loglevel" do
          expect(subject["@level"]).to eq "INFO"
        end

        it "sets @timestamp" do
          expect(subject["@timestamp"]).to eq Time.iso8601("2015-08-25T03:57:46.033Z")
        end

        it "removes the original timestamp field" do
          expect(subject["uaa_timestamp"]).to be_nil
        end

        it "sets @source.component" do
          expect(subject["@source"]["component"]).to eq "UAA"
        end

        it "sets @source.name" do
          expect(subject["@source"]["name"]).to eq "uaa-partition-7c53ed3ae2e7f5543b91/0"
        end

        it "sets @source.instance" do
          expect(subject["@source"]["instance"]).to eq 0
        end

        it "extracts remote address" do
          expect(subject["UAA"]["remote_address"]).to eq "52.19.1.74"
        end
      end
    end

    describe "UserAuthenticationSuccess" do
      when_parsing_log(
        "@type" => "syslog",
        "syslog_program" => "vcap.uaa",
        "@message" => "[2015-08-25 04:57:46.033] uaa - 4176 [http-bio-8080-exec-4] ....  INFO --- Audit: UserAuthenticationSuccess ('admin'): principal=f63e0165-b85a-40d3-9ef7-78c6698ccb2c, origin=[remoteAddress=52.19.1.74, clientId=cf], identityZoneId=[uaa]"
      ) do

        it "adds the uaa-audit tag" do
          expect(subject["tags"]).to include "uaa-audit"
        end

        it "sets @type to uaa-audit" do
          expect(subject["@type"]).to eq "uaa-audit"
        end

        it "sets @level to the loglevel" do
          expect(subject["@level"]).to eq "INFO"
        end

        it "sets @timestamp" do
          expect(subject["@timestamp"]).to eq Time.iso8601("2015-08-25T03:57:46.033Z")
        end

        it "removes the original timestamp field" do
          expect(subject["uaa_timestamp"]).to be_nil
        end

        it "sets @source.component" do
          expect(subject["@source"]["component"]).to eq "UAA"
        end

        it "sets @source.name" do
          ap subject
          expect(subject["@source"]["name"]).to eq "uaa-partition-7c53ed3ae2e7f5543b91/0"
        end
        it "sets @source.instance" do
          expect(subject["@source"]["instance"]).to eq 0
        end

        it "extracts the UAA PID" do
          expect(subject["UAA"]["pid"]).to eq 4176
        end

        it "extracts the thread name" do
          expect(subject["UAA"]["thread_name"]).to eq "http-bio-8080-exec-4"
        end

        it "extracts the UAA log type" do
          expect(subject["UAA"]["type"]).to eq "UserAuthenticationSuccess"
        end

        it "extracts the auth request data" do
          expect(subject["UAA"]["data"]).to eq "admin"
        end

        it "extracts the principal" do
          expect(subject["UAA"]["principal"]).to eq "f63e0165-b85a-40d3-9ef7-78c6698ccb2c"
        end

        it "extracts the request origin" do
          expect(subject["UAA"]["origin"]).to eq ["remoteAddress=52.19.1.74", "clientId=cf"]
        end

        it "extracts the identity zone" do
          expect(subject["UAA"]["identity_zone_id"]).to eq "uaa"
        end
      end
    end

    describe "TokenIssuedEvent" do
      when_parsing_log(
        "@type" => "syslog",
        "syslog_program" => "vcap.uaa",
        "@message" => '[2015-08-25 04:57:46.143] uaa - 4176 [http-bio-8080-exec-4] ....  INFO --- Audit: TokenIssuedEvent (\'["cloud_controller.admin","cloud_controller.write","doppler.firehose","openid","scim.read","cloud_controller.read","password.write","scim.write"]\'): principal=f63e0165-b85a-40d3-9ef7-78c6698ccb2c, origin=[client=cf, user=admin], identityZoneId=[uaa]'
      ) do

        it "extracts the UAA log type" do
          expect(subject["UAA"]["type"]).to eq "TokenIssuedEvent"
        end

        it "extracts the auth request data" do
          expect(subject["UAA"]["data"]).to eq '["cloud_controller.admin","cloud_controller.write","doppler.firehose","openid","scim.read","cloud_controller.read","password.write","scim.write"]'
        end

        it "extracts the principal" do
          expect(subject["UAA"]["principal"]).to eq "f63e0165-b85a-40d3-9ef7-78c6698ccb2c"
        end

        it "extracts the request origin" do
          expect(subject["UAA"]["origin"]).to eq ["client=cf", "user=admin"]
        end

        it "extracts the identity zone" do
          expect(subject["UAA"]["identity_zone_id"]).to eq "uaa"
        end
      end
    end

    describe "UserNotFound" do
      when_parsing_log(
        "@type" => "syslog",
        "syslog_program" => "vcap.uaa",
        "@message" => "<14>2015-08-26T06:44:05.744726+00:00 10.0.16.19 vcap.uaa [job=uaa-partition-7c53ed3ae2e7f5543b91 index=0]  [2015-08-26 06:44:05.744] uaa - 4159 [http-bio-8080-exec-7] ....  INFO --- Audit: UserNotFound (''): principal=1S0lQEF695QPAYN7mnBqQ0HpJVc=, origin=[remoteAddress=80.229.7.108], identityZoneId=[uaa]"
      ) do

        it "extracts the UAA log type" do
          expect(subject["UAA"]["type"]).to eq "UserNotFound"
        end

        it "extracts the auth request data" do
          expect(subject["UAA"]["data"]).nil?
        end

        it "extracts the principal" do
          expect(subject["UAA"]["principal"]).to eq "1S0lQEF695QPAYN7mnBqQ0HpJVc="
        end

        it "extracts the request origin" do
          expect(subject["UAA"]["origin"]).to eq ["remoteAddress=80.229.7.108"]
        end

        it "extracts the identity zone" do
          expect(subject["UAA"]["identity_zone_id"]).to eq "uaa"
        end
      end
    end
  end
end
