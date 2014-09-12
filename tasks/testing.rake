require 'rspec/core/rake_task'

desc "Generate the RCov reports when runing rspec tests"
task rcov: %w[coverage spec]

task :coverage do
  ENV['COVERAGE'] = '1'
end

desc "Remove RCov report HTML files"
task :clobber_rcov do
  rm_r 'coverage' rescue nil
end

namespace :spec do
  desc "Runs unit tests"
  RSpec::Core::RakeTask.new(:units)

  desc "Runs integration tests"
  task :integration do
    Bundler.with_clean_env do
      unless system("cd doc/example && bundle exec rspec")
        abort('Integration tests failed')
      end
    end
  end
end

desc "Runs all tests"
task spec: %w[spec:units spec:integration]
