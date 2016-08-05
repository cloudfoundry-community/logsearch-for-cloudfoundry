# encoding: utf-8
require 'test/logstash-filters/filter_test_helpers'

describe "platform.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/platform.conf")}
      }
    CONFIG
  end

  # -- test snippet's 'if' condition --
  describe "#if" do

    describe "passed" do
      when_parsing_log(
          "@metadata" => {"index" => "platform"}, # good value
          "@message" => "Some message"
      ) do

        # app tag set => 'if' succeeded
        it { expect(subject["tags"]).to include "platform" }

      end
    end

    describe "failed" do
      when_parsing_log(
          "@metadata" => {"index" => "some value"}, # bad value
          "@message" => "Some message"
      ) do

        # no tags set => 'if' failed
        it { expect(subject["tags"]).to be_nil }

        it { expect(subject["@metadata"]["index"]).to eq "some value" } # keeps unchanged
        it { expect(subject["@message"]).to eq "Some message" } # keeps unchanged

      end
    end

  end

  describe "when message is" do

    context "CF format" do
      when_parsing_log(
          "@metadata" => {"index" => "platform"},
          "@message" => "[job=nfs_z1 index=0]   Some message" # CF format
      ) do

        it { expect(subject["tags"]).to include "platform" } # platform tag

        # no parsing errors
        it { expect(subject["tags"]).not_to include "fail/cloudfoundry/platform/grok" }

        # fields
        it "should set grok fields" do
          expect(subject["@message"]).to eq "Some message"
          expect(subject["@source"]["job"]).to eq "nfs_z1"
          expect(subject["@source"]["instance"]).to eq "0"
        end

        it{ expect(subject["@type"]).to eq "cf" }
        it{ expect(subject["tags"]).to include "cf" }

      end
    end

    context "not CF format" do
      when_parsing_log(
          "@metadata" => {"index" => "platform"},
          "@message" => "Some message that fails grok" # bad format
      ) do

        it { expect(subject["tags"]).to include "platform" } # platform tag

        # get parsing error
        it { expect(subject["tags"]).to include "fail/cloudfoundry/platform/grok" }

        # no fields set
        it { expect(subject["@message"]).to eq "Some message that fails grok" } # keeps the same
        it { expect(subject["@metadata"]["index"]).to eq "platform" } # keeps the same
        it "doesn't set/override fields" do
          expect(subject["@source"]).to be_nil
          expect(subject["@type"]).to be_nil
          expect(subject["tags"]).not_to include "cf"
        end

      end
    end

  end

end
