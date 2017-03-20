# encoding: utf-8
require 'spec_helper'

describe "app-error.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/app-error.conf")}
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
        "@type" => "Error",
        "parsed_json_field" => { "source" => "abc", "code" => "def", "message" => "Some error message" },
        "@message" => "some message"
    ) do

      it { expect(parsed_results.get("tags")).to eq ["error"] }

      it { expect(parsed_results.get("@message")).to eq "Some error message" }
      it { expect(parsed_results.get("parsed_json_field")["message"]).to be_nil }
      it { expect(parsed_results.get("parsed_json_field")["source"]).to eq "abc" }
      it { expect(parsed_results.get("parsed_json_field")["code"]).to eq "def" }

      it { expect(parsed_results.get("@type")).to eq "Error" } # keeps unchanged

    end
  end

end
