# encoding: utf-8
require 'spec_helper'

describe "platform-uaa.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/platform-uaa.conf")}
      }
    CONFIG
  end

  describe "#if" do

    describe "passed" do
      when_parsing_log(
          "@source" => {"component" => "vcap.uaa"}, # good value
          "@message" => "Some message"
      ) do

        # tag set => 'if' succeeded
        it { expect(parsed_results.get("tags")).to include "uaa" }

      end
    end

    describe "failed" do
      when_parsing_log(
          "@source" => {"component" => "some value"}, # bad value
          "@message" => "Some message"
      ) do

        # no tags set => 'if' failed
        it { expect(parsed_results.get("tags")).to be_nil }

        it { expect(parsed_results.get("@type")).to be_nil } # keeps unchanged
        it { expect(parsed_results.get("@source")["component"]).to eq "some value" } # keeps unchanged
        it { expect(parsed_results.get("@message")).to eq "Some message" } # keeps unchanged

      end
    end

  end

  # -- general case
  describe "#fields when message is" do

    context "UAA" do
      context "(general event)" do
        when_parsing_log(
            "@source" => {"component" => "vcap.uaa"},
            # general UAA event
            "@message" => "[2016-07-05 04:02:18.245] uaa - 15178 [http-bio-8080-exec-14] ....  DEBUG --- FilterChainProxy: /healthz has an empty filter list"
        ) do

          it { expect(parsed_results.get("tags")).to eq ["uaa"] } # uaa tag, no fail tag
          it { expect(parsed_results.get("@type")).to eq "uaa" }
          it { expect(parsed_results.get("@source")["component"]).to eq "uaa" }

          it { expect(parsed_results.get("@message")).to eq "/healthz has an empty filter list" }
          it { expect(parsed_results.get("@level")).to eq "DEBUG" }

          it "sets [uaa] fields" do
            expect(parsed_results.get("uaa")["timestamp"]).to eq "2016-07-05 04:02:18.245"
            expect(parsed_results.get("uaa")["thread"]).to eq "http-bio-8080-exec-14"
            expect(parsed_results.get("uaa")["pid"]).to eq 15178
            expect(parsed_results.get("uaa")["log_category"]).to eq "FilterChainProxy"
          end

        end
      end

      context "(bad format)" do
        when_parsing_log(
            "@source" => {"component" => "vcap.uaa"},
            "@message" => "Some message" # bad format
        ) do

          # get parsing error
          it { expect(parsed_results.get("tags")).to eq ["uaa", "fail/cloudfoundry/platform-uaa/grok"] }
          it { expect(parsed_results.get("@type")).to eq "uaa" }
          it { expect(parsed_results.get("@source")["component"]).to eq "uaa" }

          it { expect(parsed_results.get("@message")).to eq "Some message" } # the same as before parsing

          it { expect(parsed_results.get("uaa")).to be_nil }

        end
      end
    end

    context "UAA Audit" do
      context "(general event)" do
        when_parsing_log(
          "@source" => {"component" => "vcap.uaa"},
          # general UAA event
          "@message" => "[2016-07-05 04:02:18.245] uaa - 15178 [http-bio-8080-exec-14] ....  INFO --- Audit: ClientAuthenticationSuccess ('Client authentication success'): principal=cf, origin=[remoteAddress=64.78.155.208, clientId=cf], identityZoneId=[uaa]"
        ) do

          it { expect(parsed_results.get("tags")).to eq ["uaa", "audit"] } # uaa tag, audit tag, no fail tag
          it { expect(parsed_results.get("@type")).to eq "uaa-audit" }
          it { expect(parsed_results.get("@source")["component"]).to eq "uaa" }

          it { expect(parsed_results.get("@message")).to eq "ClientAuthenticationSuccess ('Client authentication success')" }
          it { expect(parsed_results.get("@level")).to eq "INFO" }

          it "sets [uaa] fields" do
            expect(parsed_results.get("uaa")["timestamp"]).to eq "2016-07-05 04:02:18.245"
            expect(parsed_results.get("uaa")["thread"]).to eq "http-bio-8080-exec-14"
            expect(parsed_results.get("uaa")["pid"]).to eq 15178
            expect(parsed_results.get("uaa")["log_category"]).to eq "Audit"
          end

          it "sets [uaa][audit] fields" do
            expect(parsed_results.get("uaa")["audit"]["type"]).to eq "ClientAuthenticationSuccess"
            expect(parsed_results.get("uaa")["audit"]["data"]).to eq "Client authentication success"
            expect(parsed_results.get("uaa")["audit"]["principal"]).to eq "cf"
            expect(parsed_results.get("uaa")["audit"]["origin"]).to eq ["remoteAddress=64.78.155.208", "clientId=cf"]
            expect(parsed_results.get("uaa")["audit"]["identity_zone_id"]).to eq "uaa"
            expect(parsed_results.get("uaa")["audit"]["remote_address"]).to eq "64.78.155.208"
          end

          it "sets geoip for remoteAddress" do
            expect(parsed_results.get("geoip")).not_to be_nil
            expect(parsed_results.get("geoip")["ip"]).to eq "64.78.155.208"
          end

        end
      end

      context "(PrincipalAuthFailure event)" do
        when_parsing_log(
            "@source" => {"component" => "vcap.uaa"},
            # PrincipalAuthFailure event
            "@message" => "[2016-07-06 09:18:43.397] uaa - 15178 [http-bio-8080-exec-6] ....  INFO --- Audit: " +
                "PrincipalAuthenticationFailure ('null'): principal=admin, origin=[82.209.244.50], identityZoneId=[uaa]"
        ) do

          it { expect(parsed_results.get("tags")).to eq ["uaa", "audit"] } # uaa tag, audit tag, no fail tag
          it { expect(parsed_results.get("@type")).to eq "uaa-audit" }
          it { expect(parsed_results.get("@source")["component"]).to eq "uaa" }

          it { expect(parsed_results.get("@message")).to eq "PrincipalAuthenticationFailure ('null')" }
          it { expect(parsed_results.get("@level")).to eq "INFO" }

          it "sets [uaa] fields" do
            expect(parsed_results.get("uaa")["timestamp"]).to eq "2016-07-06 09:18:43.397"
            expect(parsed_results.get("uaa")["thread"]).to eq "http-bio-8080-exec-6"
            expect(parsed_results.get("uaa")["pid"]).to eq 15178
            expect(parsed_results.get("uaa")["log_category"]).to eq "Audit"
          end

          it "sets [uaa][audit] fields" do
            expect(parsed_results.get("uaa")["audit"]["type"]).to eq "PrincipalAuthenticationFailure"
            expect(parsed_results.get("uaa")["audit"]["data"]).to eq "null"
            expect(parsed_results.get("uaa")["audit"]["principal"]).to eq "admin"
            expect(parsed_results.get("uaa")["audit"]["origin"]).to eq ["82.209.244.50"]
            expect(parsed_results.get("uaa")["audit"]["identity_zone_id"]).to eq "uaa"
            expect(parsed_results.get("uaa")["audit"]["remote_address"]).to eq "82.209.244.50"
          end

          it "sets geoip for remoteAddress" do
            expect(parsed_results.get("geoip")).not_to be_nil
            expect(parsed_results.get("geoip")["ip"]).to eq "82.209.244.50"
          end

        end
      end

      context "(bad format)" do
        when_parsing_log(
            "@source" => {"component" => "vcap.uaa"},
            "@message" => "[2016-07-06 09:18:43.397] uaa - 15178 [http-bio-8080-exec-6] ....  INFO --- Audit: Some message" # bad format
        ) do

          # get parsing error
          it { expect(parsed_results.get("tags")).to eq ["uaa", "audit", "fail/cloudfoundry/platform-uaa/audit/grok"] }
          it { expect(parsed_results.get("@type")).to eq "uaa-audit" }
          it { expect(parsed_results.get("@source")["component"]).to eq "uaa" }

          it { expect(parsed_results.get("@message")).to eq "Some message" }

          it "sets [uaa] fields" do
            expect(parsed_results.get("uaa")["timestamp"]).to eq "2016-07-06 09:18:43.397"
            expect(parsed_results.get("uaa")["thread"]).to eq "http-bio-8080-exec-6"
            expect(parsed_results.get("uaa")["pid"]).to eq 15178
            expect(parsed_results.get("uaa")["log_category"]).to eq "Audit"
          end

          it { expect(parsed_results.get("uaa")["audit"]).to be_nil }

        end
      end
    end

  end

end
