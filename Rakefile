require 'erb'
require 'rake'

task :clean do
  mkdir_p "target"
  rm_rf "target/*"
end

desc "Builds filters & dashboards"
task :build => :clean do
  puts "===> Building ..."
  compile_erb 'src/logstash-filters/default.conf.erb', 'target/logstash-filters-default.conf'
  compile_erb 'src/kibana4-dashboards/kibana.json', 'target/kibana4-dashboards.json'

  puts "===> Artifacts:"
  puts `tree target`
end

desc "Runs unit tests against filters & dashboards"
task :test, [:rspec_files] => :build do |t, args|
  args.with_defaults(:rspec_files => "$(find test -name *spec.rb)")
	puts "===> Testing ..."
  sh %Q[ JAVA_OPTS="$JAVA_OPTS -XX:+TieredCompilation -XX:TieredStopAtLevel=1" vendor/logstash/bin/rspec #{args[:rspec_files]} ]
end

def compile_erb(source_file, dest_file)
  if File.extname(source_file) == '.erb'
    output = ERB.new(File.read(source_file)).result(binding)
    File.write(dest_file, output)
  else
    cp source_file, dest_file
  end
end
