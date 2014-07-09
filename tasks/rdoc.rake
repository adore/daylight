require 'rdoc/task'

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.main     = 'README.md'
  rdoc.title    = 'Daylight'
  rdoc.rdoc_dir = 'rdoc'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.md', 'doc/*.md', 'lib/**/*.rb', 'rails/**/*.rb')
end
