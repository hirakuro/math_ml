require "rdoc/task"
require "rspec/core/rake_task"
require "rubygems/package_task"

VER = "0.14"

Rake::RDocTask.new(:rdoc) do |rdoc|
	rdoc.options << "-S"
	rdoc.options << "-w" << "3"
	rdoc.options << "-c" << "UTF-8"
	rdoc.rdoc_files.include("lib/**/*.rb")
	rdoc.title = "MathML Library"
	rdoc.main = "README"
	rdoc.rdoc_files.include(FileList["lib/**/*.rb", "README"])
end

gem_spec = Gem::Specification.new do |s|
	s.platform = Gem::Platform::RUBY
	s.files = FileList["Rakefile*", "lib/**/*", "spec/**/*"]

	s.name = "math_ml"
	s.rubyforge_project = "mathml"
	s.version = VER
	s.summary = "MathML Library"
	s.author = "KURODA Hiraku"
	s.email = "hirakuro@gmail.com"
	s.homepage = "http://mathml.rubyforge.org/"
	s.add_dependency("eim_xml")
end

Gem::PackageTask.new(gem_spec) do |t|
	t.need_tar_gz = true
end


RSpec::Core::RakeTask.new do |s|
	s.rspec_opts ||= []
	s.rspec_opts << "-c"
	s.rspec_opts << "-I" << "." << "-I" << "./lib" << "-I" << "./external/lib"
end

namespace :spec do
	task :coverage do |t|
		cmd = "rcov $(which rspec)"
		cmd << " -I lib -x .bundle,gems"
		cmd << " spec/util.rb $(find spec -name \\*_spec.rb)"
		sh cmd
	end

	RSpec::Core::RakeTask.new(:profile) do |s|
		s.verbose = false
		s.rspec_opts ||= []
		s.rspec_opts << "-c"
		s.rspec_opts << "-I" << "." << "-I" << "./lib" << "-I" << "./external/lib"
		s.rspec_opts << "-p"
	end

	RSpec::Core::RakeTask.new(:symbols) do |s|
		s.pattern = "./symbols/**/*_spec.rb"
		s.rspec_opts = %w[-c -I lib -I external/lib]
	end
end

task :package do
	name = "math_ml-#{VER}"
	Dir.chdir "pkg" do
		rm "#{name}.tar.gz"
		sh "tar zcf #{name}.tar.gz #{name}/"
	end
end

task :default => "spec"
