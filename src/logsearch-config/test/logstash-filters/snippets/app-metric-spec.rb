# encoding: utf-8
require 'test/logstash-filters/filter_test_helpers'

describe "app-metric.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/app-metric.conf")}
      }
    CONFIG
  end

  describe "when metric case" do
    when_parsing_log(
        "@type" => "ContainerMetric", # metric case
        "app" => { "instance_index" => 5, "cpu_percentage" => 123, "memory_bytes" => 456, "disk_bytes" => 789 },

        "@source" => { "component" => "some component", "instance" => "some value" },
        "@message" => "some message"
    ) do

      # metric tag is set
      it { expect(subject["tags"]).to eq ["metric"] }

      # fields
      it { expect(subject["@source"]["component"]).to eq "METRIC" }
      it { expect(subject["@source"]["instance"]).to eq "5" }
      it { expect(subject["app"]["instance_index"]).to be_nil }
      it { expect(subject["@message"]).to eq "Container metrics: cpu=123, memory=456, disk=789" }

      it "sets metric-specific fields" do
        expect(subject["metric"]["cpu_percentage"]).to eq 123
        expect(subject["metric"]["memory_bytes"]).to eq 456
        expect(subject["metric"]["disk_bytes"]).to eq 789
      end

    end
  end

  describe "when NOT metric case" do
    when_parsing_log(
        "@type" => "some type", # bad type
        "app" => { "instance_index" => 5, "cpu_percentage" => 123, "memory_bytes" => 456, "disk_bytes" => 789 },

        "@source" => { "component" => "some component", "instance" => "some value" },
        "@message" => "some message"
    ) do

      # metric tag is NOT set
      it { expect(subject["tags"]).to be_nil }

      # fields
      it { expect(subject["@source"]["component"]).to eq "some component" } # keeps unchanged
      it { expect(subject["@source"]["instance"]).to eq "some value" } # keeps unchanged
      it { expect(subject["@message"]).to eq "some message" } # keeps unchanged
      it { expect(subject["metric"]).to be_nil }

    end
  end

end
