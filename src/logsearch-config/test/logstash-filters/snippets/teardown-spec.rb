# encoding: utf-8
require 'test/filter_test_helpers'

describe "teardown.conf" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/teardown.conf")}
      }
    CONFIG
  end

  describe "when @level is set from [syslog_severity_code]" do

    context "([syslog_severity_code] = 2)" do
      when_parsing_log( "syslog_severity_code" => 2 ) do
        it { expect(subject["@level]"]).to eq "ERROR" }
      end
    end

    context "([syslog_severity_code] = 3)" do
      when_parsing_log( "syslog_severity_code" => 3 ) do
        it { expect(subject["@level"]).to eq "ERROR" }
      end
    end

    context "([syslog_severity_code] = 4)" do
      when_parsing_log( "syslog_severity_code" => 4 ) do
        it { expect(subject["@level"]).to eq "WARN" }
      end
    end

    context "([syslog_severity_code] = 5)" do
      when_parsing_log( "syslog_severity_code" => 5 ) do
        it { expect(subject["@level"]).to eq "WARN" }
      end
    end

    context "([syslog_severity_code] = 6)" do
      when_parsing_log( "syslog_severity_code" => 6 ) do
        it { expect(subject["@level"]).to eq "INFO" }
      end
    end

    context "([syslog_severity_code] = 7)" do
      when_parsing_log( "syslog_severity_code" => 7 ) do
        it { expect(subject["@level"]).to eq "DEBUG" }
      end
    end

    context "([syslog_severity_code] = 8)" do
      when_parsing_log( "syslog_severity_code" => 8 ) do
        it { expect(subject["@level"]).to be_nil }
      end
    end

  end

  describe "when @level is not set" do

    context "([syslog_severity_code] = 2)" do
      when_parsing_log( "some_field" => "some_value" ) do
        it { expect(subject["@level"]).to be_nil }
      end
    end
  end

  describe "cleanup" do

    when_parsing_log(
      "syslog_pri" => "abc",
      "syslog_facility" => "def",
      "syslog_facility_code" => "ghi",
      "syslog_message" => "jkl",
      "syslog_severity" => "mno",
      "syslog_severity_code" => "pqr",
      "syslog_program" => "stu",
      "syslog_timestamp" => "vw",
      "syslog_hostname" => "xy",
      "syslog_pid" => "z",
      "tags" => ["t1", "t2"],
      "@level" => "lowercase value",
      "@version" => "some version"
    ) do

      it "should remove syslog fields" do
        expect(subject["syslog_pri"]).to be_nil
        expect(subject["syslog_facility"]).to be_nil
        expect(subject["syslog_facility_code"]).to be_nil
        expect(subject["syslog_message"]).to be_nil
        expect(subject["syslog_severity"]).to be_nil
        expect(subject[ "syslog_severity_code"]).to be_nil
        expect(subject["syslog_program"]).to be_nil
        expect(subject["syslog_timestamp"]).to be_nil
        expect(subject["syslog_hostname"]).to be_nil
        expect(subject["syslog_pid"]).to be_nil
      end

      it "should rename tags field" do
        expect(subject["@tags"]).to eq ["t1", "t2"]
        expect(subject["tags"]).to be_nil
      end

      it { expect(subject["@level"]).to eq "LOWERCASE VALUE" }

      it { expect(subject["@version"]).to be_nil }

    end

  end

end
