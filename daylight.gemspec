$:.push File.expand_path('../lib', __FILE__)
require 'daylight/version'

Gem::Specification.new do |s|
  s.name        = 'daylight'
  s.version     = Daylight::VERSION
  s.platform    = Gem::Platform::RUBY
  s.license     = 'Apache-2.0'
  s.authors     = ['Reid MacDonald', 'Doug McInnes']
  s.email       = ['reidmix@gmail.com', 'doug@dougmcinnes.com']
  s.homepage    = 'https://github.com/att-cloud/daylight'
  s.summary     = "Allow ActiveResource to function more like ActiveRecord"
  s.description = <<-DESC
    Daylight extends Rails on the server and ActiveResource in the client to
    allow your ActiveResource client API to perform more like to ActiveRecord
  DESC

  s.add_runtime_dependency 'rails',                    '>= 4.0.1', '~> 4.1.0'
  s.add_runtime_dependency 'activeresource',           '~> 4.0.0'
  s.add_runtime_dependency 'haml',                     '~> 4.0.5'
  s.add_runtime_dependency 'actionpack-page_caching',  '~> 1.0.2'
  s.add_runtime_dependency 'hanna-bootstrap',          '~> 0.0.5'
  s.add_runtime_dependency 'active_model_serializers', '~> 0.8.1'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-rails',    '~> 2.14.0'
  s.add_development_dependency 'simplecov-rcov', '~> 0.2.3'
  s.add_development_dependency 'webmock',        '~> 1.18.0'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'factory_girl'
  s.add_development_dependency 'faker'

  s.files            = `git ls-files -- {app,config,lib,rails}/*`.split("\n")
  s.test_files       = `git ls-files -- spec/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files = `git ls-files -- **/*.md`.split("\n") + %w[README.md]
  s.require_paths    = ['lib']
end
