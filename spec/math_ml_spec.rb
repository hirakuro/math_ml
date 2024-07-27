require 'math_ml'

describe MathML do
  it 'does not raise error when math_ml.rb is required twice' do
    expect { MathML::LaTeX::Parser.new }.not_to raise_error if require_relative('../lib/math_ml')
  end

  it '.pcstring' do
    expect(MathML.pcstring('<>&"\'').to_s).to eq('&lt;&gt;&amp;&quot;&apos;')
    expect(MathML.pcstring('<tag>&amp;"\'</tag>', true).to_s).to eq('<tag>&amp;"\'</tag>')
  end
end
