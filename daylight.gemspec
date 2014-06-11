$:.push File.expand_path('../lib', __FILE__)
require 'daylight/version'

Gem::Specification.new do |s|
  s.name        = 'daylight'
  s.version     = Daylight::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Reid MacDonald', 'Doug McInnes']
  s.email       = ['reidmix@gmail.com', 'doug@dougmcinnes.com']
  s.homepage    = ''
  s.summary     = %q{}
  s.description = %q{}

  s.add_runtime_dependency 'rails',                   '~> 4.0.1'
  s.add_runtime_dependency 'activeresource',          '~> 4.0.0'
  s.add_runtime_dependency 'haml',                    '~> 4.0.5'
  s.add_runtime_dependency 'actionpack-page_caching', '~> 1.0.2'
  s.add_runtime_dependency 'therubyracer',            '~> 0.12.1'
  s.add_runtime_dependency 'hanna-bootstrap',         '~> 0.0.5'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-rails',    '~> 2.14.0'
  s.add_development_dependency 'simplecov-rcov', '~> 0.2.3'
  s.add_development_dependency 'fakeweb'
  s.add_development_dependency 'webmock',        '~> 1.16.1'
  s.add_development_dependency 'artifice',       '~> 0.6'
  s.add_development_dependency 'active_model_serializers'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'factory_girl'
  s.add_development_dependency 'faker'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
