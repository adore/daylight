require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc "Generate the coverage report when runing rspec tests"
task rcov: %w[coverage spec]

task :coverage do
  ENV['COVERAGE'] = '1'
end
