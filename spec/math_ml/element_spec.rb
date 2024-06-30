require "math_ml"

describe MathML::Element do
	it "#display_style and #as_display_style" do
		expect(MathML::Element.new("test").display_style).to eq(nil)
		e = MathML::Element.new("test")
		r = e.as_display_style
		expect(r).to equal(e)
		expect(e.display_style).to be true
	end

	it "#pop" do
		e = MathML::Element.new("super")
		s = MathML::Element.new("sub")

		expect(e.pop).to be_nil

		e << s
		expect(e.pop).to equal(s)
		expect(e.pop).to be_nil

		e << "text"
		expect(e.pop).to eq("text")
		expect(e.pop).to be_nil
	end

	it "#to_s" do
		e = MathML::Element.new("e")
		e << "test<"
		expect(e.to_s).to eq("<e>test&lt;</e>")
	end
end
