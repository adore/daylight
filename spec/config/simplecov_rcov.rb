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

  SimpleCov.adapters.define 'api' do
    load_adapter 'test_frameworks'

    add_group 'Client', 'lib/daylight'
  end

  SimpleCov.start 'api'
end
