# Test for math_ml/util.rb
#
# Copyright (C) 2007, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.

require "test/unit"
require "math_ml/string"

class TC_MathML_String < Test::Unit::TestCase
	def setup
		@mlp = MathML::LaTeX::Parser.new
	end

	def test_mathml_latex_parser
		assert_kind_of(MathML::LaTeX::Parser, MathML::String.mathml_latex_parser)
		mlp = MathML::LaTeX::Parser.new
		MathML::String.mathml_latex_parser = mlp
		assert_equal(mlp.object_id, MathML::String.mathml_latex_parser.object_id)
		assert_raises(TypeError){MathML::String.mathml_latex_parser=String}
		assert_equal(mlp.object_id, MathML::String.mathml_latex_parser.object_id)

		MathML::String.mathml_latex_parser = nil
		assert_kind_of(MathML::LaTeX::Parser, MathML::String.mathml_latex_parser)
		assert_not_equal(mlp.object_id, MathML::String.mathml_latex_parser.object_id)
	end

	def test_to_mathml
		assert_equal(@mlp.parse("").to_s, "".to_mathml.to_s)
		assert_equal(@mlp.parse("", true).to_s, "".to_mathml(true).to_s)

		MathML::String.mathml_latex_parser.macro.parse(<<'EOT')
\newcommand{\test}{x}
EOT
		assert_equal(@mlp.parse("x").to_s, '\test'.to_mathml.to_s)
	end
end
