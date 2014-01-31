if ENV["COVERAGE"]
  require 'simplecov'

  if ENV["COVERALLS"]
    require 'coveralls'
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
    ]
  end

  SimpleCov.start 'rails' do
    add_filter 'vendor'
  end
end
