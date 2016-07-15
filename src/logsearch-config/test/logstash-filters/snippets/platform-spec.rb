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

  describe "when message is" do

    context "CF format" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "some_program",
          "@message" => "[job=nfs_z1 index=0]   Some message" # CF format
      ) do

        # no parsing errors
        it { expect(subject["tags"]).not_to include "fail/cloudfoundry/platform/grok" }

        # fields
        it "should set grok fields" do
          expect(subject["@message"]).to eq "Some message"
          expect(subject["@source"]["name"]).to eq "nfs_z1/0"
          expect(subject["@source"]["job"]).to eq "nfs_z1"
          expect(subject["@source"]["instance"]).to eq "0"
        end

        it "should set general fields" do
          expect(subject["@metadata"]["index"]).to eq "platform"
          expect(subject["@type"]).to eq "cf"
          expect(subject["tags"]).to include "cf"
        end

      end
    end

    context "bad format" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "some_program",
          "@message" => "Some message that fails grok" # bad format
      ) do

        # get parsing error
        it { expect(subject["tags"]).to include "fail/cloudfoundry/platform/grok" }

        # no fields set
        it "shouldn't set grok fields" do
          expect(subject["@source"]).to be_nil
          expect(subject["@message"]).to eq "Some message that fails grok" # the same as before parsing
        end

        it "shouldn't set general fields" do
          expect(subject["@metadata"]["index"]).to be_nil # @metadata is system field so it exists even if not set ..
          # ..(that's why we should check exactly @metadata.index for nil)

          expect(subject["@type"]).to eq "relp"
          expect(subject["tags"]).not_to include "cf"
        end

      end
    end

  end

  describe "when platform case" do

    context "(@type = syslog)" do
      when_parsing_log(
          "@type" => "syslog", # good value
          "syslog_program" => "some_program",
          "@message" => "Some message here"
      ) do

        # platform tag => if passed
        it { expect(subject["tags"]).to include "fail/cloudfoundry/platform/grok" }

      end
    end

    context "(@type = relp)" do
      when_parsing_log(
          "@type" => "relp", # good value
          "syslog_program" => "some_program",
          "@message" => "Some message here"
      ) do

        # platform tag => if passed
        it { expect(subject["tags"]).to include "fail/cloudfoundry/platform/grok" }

      end
    end

  end

  describe "when NOT platform case" do

    context "(bad @type)" do
      when_parsing_log(
          "@type" => "Some type", # bad value
          "syslog_program" => "some_program",
          "@message" => "Some message here"
      ) do

        # no tags => 'if' failed
        it { expect(subject["tags"]).to be_nil }

      end
    end

    context "(bad syslog_program)" do
      when_parsing_log(
          "@type" => "relp",
          "syslog_program" => "doppler", # bad value
          "@message" => "Some message here"
      ) do

        # no tags => 'if' failed
        it { expect(subject["tags"]).to be_nil }

      end
    end

  end

end
