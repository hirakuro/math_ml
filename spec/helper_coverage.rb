require 'simplecov'

SimpleCov.start :bundler_filter do
  add_filter '/gems/'
  track_files 'spec/**/*_spec.rb'
end
