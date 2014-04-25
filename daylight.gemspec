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

  s.add_runtime_dependency 'activeresource', '~> 4.0.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
