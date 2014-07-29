namespace :ci do
  INTEGRATION_DIR = "doc/example"

  def update_gemfile!
    ENV['BUILD_GEMFILE'] =
      if ENV['BUILD_GEMFILE']
        ENV['BUILD_GEMFILE'].gsub(ENV['PWD'], File.join(ENV['PWD'], INTEGRATION_DIR))
      else
        File.join(ENV['PWD'], INTEGRATION_DIR, 'Gemfile')
      end

    puts "export BUILD_GEMFILE=#{ENV['BUILD_GEMFILE']}"
  end

  desc "Runs continuous integration unit tests"
  task units: :spec

  desc "Runs continuous integration integration tests"
  task :integration do
    update_gemfile!

    Bundler.with_clean_env do
      unless system("cd doc/example && bundle install && bundle exec rspec")
        abort('Integration tests failed')
      end
    end
  end
end

desc "Runs all continuous integration tests"
task ci: %w[ci:units ci:integration]
