# encoding: utf-8
require 'test/filter_test_helpers'

describe "platform.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/platform.conf")}
      }
    CONFIG
  end

  describe "when 'grok'" do

    context "succeeded" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "some_program",
          "@message" => "[job=nfs_z1 index=0]   Some message"
      ) do

        # no parsing errors
        it { expect(subject["tags"]).not_to include "fail/cloudfoundry/platform/grok" }

        # fields
        it "should set grok fields" do
          expect(subject["@message"]).to eq "Some message"
          expect(subject["@source"]["name"]).to eq "nfs_z1/0"
          expect(subject["@source"]["instance"]).to eq 0
        end

        it "should set basic fields" do
          expect(subject["@metadata"]["index"]).to eq "platform"
          expect(subject["@type"]).to eq "relp_cf"
          expect(subject["tags"]).to include "cf"
        end

      end
    end

    context "failed" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "some_program",
          "@message" => "Some message that fails grok"
      ) do

        # get parsing error
        it { expect(subject["tags"]).to include "fail/cloudfoundry/platform/grok" }

        # no fields set
        it "shouldn't set grok fields" do
          expect(subject["@source"]).to be_nil
          expect(subject["@message"]).to eq "Some message that fails grok" # the same as before parsing
        end

        it "shouldn't set basic fields" do
          expect(subject["@metadata"]["index"]).to be_nil # @metadata is system field so it exists even if not set ..
          # ..(that's why we should check exactly @metadata.index for nil)

          expect(subject["@type"]).to eq "relp"
          expect(subject["tags"]).not_to include "cf"
        end

      end
    end

  end


  describe "when 'if' condition" do

    context "passed (@type = syslog)" do
      when_parsing_log(
          "@type" => "syslog", # syslog
          "syslog_program" => "some_program",
          "@message" => "Some message here"
      ) do

        # grok tag => grok parsing was done => if succeeded
        it { expect(subject["tags"]).to include "fail/cloudfoundry/platform/grok" }

      end
    end

    context "passed (@type = relp)" do
      when_parsing_log(
          "@type" => "relp", # relp
          "syslog_program" => "some_program",
          "@message" => "Some message here"
      ) do

        # grok tag => grok parsing was done => if succeeded
        it { expect(subject["tags"]).to include "fail/cloudfoundry/platform/grok" }

      end
    end

    context "failed (bad syslog_program)" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "doppler", # bad value
          "@message" => "Some message here"
      ) do

        # no grok tag => no grok parsing was done => 'if' failed
        it { expect(subject["tags"]).to be_nil }

      end
    end

    context "failed (bad @type)" do
      when_parsing_log(
          "@type" => "Some type", # bad value
          "syslog_program" => "some_program",
          "@message" => "Some message here"
      ) do

        # no grok tag => no grok parsing was done => 'if' failed
        it { expect(subject["tags"]).to be_nil }

      end
    end

  end

end
