# encoding: utf-8
require 'test/filter_test_helpers'

describe "setup.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/setup.conf")}
      }
    CONFIG
  end

  describe "when message" do
    context "is useless (empty)" do
      when_parsing_log(
          "@message" => "" # empty
      ) do

        # event is dropped
        it { expect(subject).to be_nil }

      end
    end

    context "useless (blank)" do
      when_parsing_log(
          "@message" => "    " # blank
      ) do

        # event is dropped
        it { expect(subject).to be_nil }

      end
    end

    context "contains unicode (\u0000)" do
      when_parsing_log(
          "@message" => "a\u0000bc"
      ) do

        # event is dropped
        it { expect(subject["@message"]).to eq "abc" }

      end
    end

    context "is normal" do
      when_parsing_log(
          "@type" => "some-type",
          "syslog_program" => "some-program",
          "syslog_pri" => "5",
          "host" => "1.2.3.4",
          "@message" => "Some message"
      ) do

        # event is not dropped
        it { expect(subject).not_to be_nil }

        # fields
        it { expect(subject["@metadata"]["index"]).to eq "unparsed" }
        it { expect(subject["@input"]).to eq "some-type" }
        it { expect(subject["@shipper"]["priority"]).to eq "5" }
        it { expect(subject["@shipper"]["name"]).to eq "some-program_some-type" }
        it { expect(subject["@source"]["component"]).to eq "some-program" }
        it { expect(subject["@source"]["host"]).to eq "1.2.3.4" }
        it { expect(subject["host"]).to be_nil }

      end
    end

  end

end
