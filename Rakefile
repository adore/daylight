# load all the rake tasks
Dir[File.expand_path('../tasks/*.rake', __FILE__)].each { |f| load f }

desc "Default task is to run rspec tests"
task default: 'spec:units'

desc "Remove all generated files"
task clean: %w[clobber_rcov clobber_rdoc clobber_gem]
