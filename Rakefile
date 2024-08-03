require 'rdoc/task'
require 'rspec/core/rake_task'

VER = '0.14'

Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.options << '-S'
  rdoc.options << '-w' << '3'
  rdoc.options << '-c' << 'UTF-8'
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.title = 'MathML Library'
  rdoc.main = 'README'
  rdoc.rdoc_files.include(FileList['lib/**/*.rb', 'README'])
end

RSpec::Core::RakeTask.new do |s|
  s.rspec_opts ||= []
  s.rspec_opts << '-c'
end

namespace :spec do
  RSpec::Core::RakeTask.new(:coverage) do |s|
    s.rspec_opts ||= []
    s.rspec_opts << '-c'
    s.rspec_opts << '-r' << './spec/helper_coverage'
  end

  RSpec::Core::RakeTask.new(:profile) do |s|
    s.verbose = false
    s.rspec_opts ||= []
    s.rspec_opts << '-c'
    s.rspec_opts << '-p'
  end

  RSpec::Core::RakeTask.new(:symbols) do |s|
    s.pattern = './symbols/**/*_spec.rb'
    s.rspec_opts = %w[-c -I lib -I external/lib]
  end
end

task default: 'spec'
