namespace :ci do
  desc "Runs continuous integration unit tests"
  task units: :spec

  desc "Runs continuous integration integration tests"
  task :integration do
    ENV['TEST_DIR'] ||= '.'
    puts ENV.inspect
    ENV['BUILD_GEMFILE'] = File.join(ENV['PWD'], ENV['TEST_DIR'], 'Gemfile')
    puts "export BUILD_GEMFILE=#{ENV['BUILD_GEMFILE']}"

    Bundler.with_clean_env do
      unless system("bundle exec rspec #{ENV['TEST_DIR']}")
        abort('Integration tests failed')
      end
    end
  end
end

desc "Runs all continuous integration tests"
task ci: %w[ci:units ci:integration]
