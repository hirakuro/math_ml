#!/usr/bin/ruby
HERE = File.dirname(__FILE__)
BASE = "#{HERE}/.."
$:.unshift("#{BASE}/lib", "#{BASE}/external/lib")
require "math_ml"
require "math_ml/symbol/character_reference"
require "math_ml/symbol/utf8"

psl = [nil, :character, :utf8].map do |s|
	opt = {}
	opt[:symbol] = s if s
	MathML::LaTeX::Parser.new(opt)
end
lower = ("a".."z").to_a.join
upper = ("A".."Z").to_a.join
src = %w[mathbb mathfrak mathscr].map{|com|
	["\\#{com}{#{lower}}","\\#{com}{#{upper}}"]
}.flatten


list = psl.map{|ps|
	src.map{|s|
		"<p>" << ps.parse(s).to_s << "</p>"
	}
}

mathml = []
(0...6).each do |i|
	(0...3).each do |j|
		mathml << list[j][i]
	end
end

puts <<EOT
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN" "http://www.w3.org/Math/DTD/mathml2/xhtml-math11-f.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja">
<head>
<title>SAMPLE</title>
</head>
<body>
#{mathml.join("\n")}
</body>
</html>
EOT
