namespace :ci do
  desc "Runs continuous integration unit tests"
  task units: :spec

  desc "Runs continuous integration integration tests"
  task :integration do
    Bundler.with_clean_env do
      unless system("cd doc/example && bundle install && bundle exec rspec")
        abort('Integration tests failed')
      end
    end
  end
end

desc "Runs all continuous integration tests"
task ci: %w[ci:units ci:integration]
