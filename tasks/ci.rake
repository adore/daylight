namespace :ci do
  desc "Runs continuous integration unit tests"
  task units: :spec

  desc "Runs continuous integration integration tests"
  task :integration do
    Bundler.with_clean_env do
      system("cd doc/example && bundle exec rspec")
    end
  end
end

desc "Runs all continuous integration tests"
task ci: %w[ci:units ci:integration]
