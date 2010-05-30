load "Rakefile.utirake"

VER = "0.8.1"

UtiRake.setup do
	external("https://hg.hinet.mydns.jp", %w[eim_xml])

	rdoc do |t|
		t.title = "MathML Library"
		t.main = "README"
		t.rdoc_files << FileList["lib/**/*.rb", "README"]
	end

	publish("mathml", "hiraku") do
		cp "index.html", "html/index.html"
	end

	gemspec do |s|
		s.name = "math_ml"
		s.rubyforge_project = "mathml"
		s.version = VER
		s.summary = "MathML Library"
		s.author = "KURODA Hiraku"
		s.email = "hiraku@hinet.mydns.jp"
		s.homepage = "http://mathml.rubyforge.org/"
		s.add_dependency("eim_xml")
	end

	rcov_spec do |s|
		s.spec_files << FileList["symbols/**/*_spec.rb"]
	end

	spec do |s|
#		s.spec_opts << "-b"
	end
	alias_task
end

namespace :spec do
	Spec::Rake::SpecTask.new(:symbols) do |s|
		s.spec_files = FileList["./symbols/**/*_spec.rb"]
		s.spec_opts << "-c"
		s.libs << "lib" << "external/lib"
	end
end

task :default => :spec
task "spec:no_here" => "spec:apart"
task :all => [:spec, "spec:symbols"]
