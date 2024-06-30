require "math_ml"

describe MathML do
	it "should not raise error when math_ml.rb is required twice" do
		if require_relative("../lib/math_ml")
			lambda{MathML::LaTeX::Parser.new}.should_not raise_error
		end
	end

	it ".pcstring" do
		MathML.pcstring('<>&"\'').to_s.should == "&lt;&gt;&amp;&quot;&apos;"
		MathML.pcstring('<tag>&amp;"\'</tag>', true).to_s.should == '<tag>&amp;"\'</tag>'
	end
end
