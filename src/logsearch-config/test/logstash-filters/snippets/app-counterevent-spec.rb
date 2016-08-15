# encoding: utf-8
require 'test/logstash-filters/filter_test_helpers'

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
      it { expect(subject["tags"]).to be_nil }

    end
  end

  # -- general case
  describe "#fields" do
    when_parsing_log(
        "@type" => "CounterEvent",
        "parsed_json_field" => { "name" => "abc", "delta" => 123, "total" => 456 },
        "@message" => "some message"
    ) do

      it { expect(subject["tags"]).to eq ["counterevent"] }

      it { expect(subject["@message"]).to eq "abc (delta=123, total=456)" }
      it { expect(subject["parsed_json_field"]["name"]).to eq "abc" }
      it { expect(subject["parsed_json_field"]["delta"]).to eq 123 }
      it { expect(subject["parsed_json_field"]["total"]).to eq 456 }

      it { expect(subject["@type"]).to eq "CounterEvent" } # keeps unchanged

    end
  end

end
