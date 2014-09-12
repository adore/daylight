require 'rubygems/package'

namespace :gem do
  def base_dir
    File.expand_path('../..', __FILE__)
  end

  def specfile
    File.join(base_dir, 'daylight.gemspec')
  end

  def gemfile
    File.join(base_dir, gemspec.file_name)
  end

  def gemspec
    @gemspec ||= Gem::Specification.load specfile
  end

  task :build do
    Gem::Package.build(gemspec)
  end

  task :clean do
    rm_r gemspec.file_name rescue nil
  end
end

desc "Build the Daylight gem"
task gem: %w[gem:build]

desc "Deletes the Daylight gem"
task clobber_gem: %w[gem:clean]


