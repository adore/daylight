if %w[COVERAGE JENKINS_URL].any? { |switch| ENV.keys.include? switch }

  require 'simplecov'
  require 'simplecov-rcov'

  class SimpleCov::Formatter::MergedFormatter
    def format(result)
       SimpleCov::Formatter::HTMLFormatter.new.format(result)
       SimpleCov::Formatter::RcovFormatter.new.format(result)
    end
  end
  SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter

  SimpleCov.profiles.define 'api' do
    load_profile 'test_frameworks'

    add_group 'Client API', 'lib/daylight'
    add_group 'Server API', 'rails/daylight'
    add_group 'Rails Exts', 'rails/extensions'
    add_group 'Doc Engine', 'app'

    add_filter '/config/'
  end

  SimpleCov.start 'api'
end
