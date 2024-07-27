require 'math_ml/string'

describe MathML::String do
  it '.mathml_latex_parser' do
    expect(MathML::String.mathml_latex_parser).to be_kind_of(MathML::LaTeX::Parser)
    mlp = MathML::LaTeX::Parser.new
    MathML::String.mathml_latex_parser = mlp
    expect(MathML::String.mathml_latex_parser).to equal(mlp)
    expect { MathML::String.mathml_latex_parser = String }.to raise_error(TypeError)
    expect(MathML::String.mathml_latex_parser).to equal(mlp)

    MathML::String.mathml_latex_parser = nil
    expect(MathML::String.mathml_latex_parser).to be_kind_of(MathML::LaTeX::Parser)
    expect(MathML::String.mathml_latex_parser).not_to equal(mlp)
  end
end

describe String do
  it '#parse' do
    mlp = MathML::LaTeX::Parser.new
    expect(''.to_mathml.to_s).to eq(mlp.parse('').to_s)
    expect(''.to_mathml(true).to_s).to eq(mlp.parse('', true).to_s)

    MathML::String.mathml_latex_parser.macro.parse(<<~'EOT')
      \newcommand{\test}{x}
    EOT
    expect('\test'.to_mathml.to_s).to eq(mlp.parse('x').to_s)
  end
end
