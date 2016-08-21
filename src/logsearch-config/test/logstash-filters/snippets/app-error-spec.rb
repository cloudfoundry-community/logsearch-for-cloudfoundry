# encoding: utf-8
require 'test/logstash-filters/filter_test_helpers'

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
      it { expect(subject["tags"]).to be_nil }

    end
  end

  # -- general case
  describe "#fields" do
    when_parsing_log(
        "@type" => "Error",
        "parsed_json_field" => { "source" => "abc", "code" => "def", "message" => "Some error message" },
        "@message" => "some message"
    ) do

      it { expect(subject["tags"]).to eq ["error"] }

      it { expect(subject["@message"]).to eq "Some error message" }
      it { expect(subject["parsed_json_field"]["message"]).to be_nil }
      it { expect(subject["parsed_json_field"]["source"]).to eq "abc" }
      it { expect(subject["parsed_json_field"]["code"]).to eq "def" }

      it { expect(subject["@type"]).to eq "Error" } # keeps unchanged

    end
  end

end
