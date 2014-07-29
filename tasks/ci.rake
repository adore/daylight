namespace :ci do
  def update_gemfile!
    ENV['BUNDLE_GEMFILE'] =
      if ENV['BUNDLE_GEMFILE']
        ENV['BUNDLE_GEMFILE'].gsub(ENV['PWD'], File.join(ENV['PWD'], ENV['TEST_DIR']))
      else
        File.join(ENV['PWD'], ENV['TEST_DIR'], 'Gemfile')
      end

    puts "export BUNDLE_GEMFILE=#{ENV['BUNDLE_GEMFILE']}"
  end

  desc "Runs continuous integration unit tests"
  task units: :spec

  desc "Runs continuous integration integration tests"
  task :integration do
    update_gemfile!

    Bundler.with_clean_env do
      unless system("bundle exec rspec ENV['TEST_DIR']")
        abort('Integration tests failed')
      end
    end
  end
end

desc "Runs all continuous integration tests"
task ci: %w[ci:units ci:integration]
