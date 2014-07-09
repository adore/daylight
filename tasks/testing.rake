require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc "Generate the RCov reports when runing rspec tests"
task rcov: %w[coverage spec]

task :coverage do
  ENV['COVERAGE'] = '1'
end

desc "Remove RCov report HTML files"
task :clobber_rcov do
  rm_r 'coverage' rescue nil
end
