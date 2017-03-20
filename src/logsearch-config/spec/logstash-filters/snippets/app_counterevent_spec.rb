# encoding: utf-8
require 'spec_helper'

describe "app-counterevent.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/app-counterevent.conf")}
      }
    CONFIG
  end

  describe "#if failed" do
    when_parsing_log(
        "@type" => "some type", # bad type
        "parsed_json_field" => { "field" => "value" },
        "@message" => "some message"
    ) do

      # tag is NOT set
      it { expect(parsed_results.get("tags")).to be_nil }

    end
  end

  # -- general case
  describe "#fields" do
    when_parsing_log(
        "@type" => "CounterEvent",
        "parsed_json_field" => { "name" => "abc", "delta" => 123, "total" => 456 },
        "@message" => "some message"
    ) do

      it { expect(parsed_results.get("tags")).to eq ["counterevent"] }

      it { expect(parsed_results.get("@message")).to eq "abc (delta=123, total=456)" }
      it { expect(parsed_results.get("parsed_json_field")["name"]).to eq "abc" }
      it { expect(parsed_results.get("parsed_json_field")["delta"]).to eq 123 }
      it { expect(parsed_results.get("parsed_json_field")["total"]).to eq 456 }

      it { expect(parsed_results.get("@type")).to eq "CounterEvent" } # keeps unchanged

    end
  end

end
