require 'math_ml'

describe MathML::LaTeX::Scanner do
  def new_scanner(src)
    MathML::LaTeX::Scanner.new(src)
  end

  it '#done, #rest' do
    s = new_scanner('0123')
    s.pos = 2
    expect(s.done).to eq('01')
    expect(s.rest).to eq('23')
  end

  it '#_check' do
    s = new_scanner(' ')
    expect(s._check(/\s/)).to eq(' ')
    expect(s.pos).to eq(0)
  end

  it '#_scan' do
    s = new_scanner(' ')
    expect(s._scan(/\s/)).to eq(' ')
    expect(s.pos).to eq(1)
  end

  it '#check' do
    s = new_scanner(' a')
    expect(s.check(/a/)).to eq('a')
    expect(s.pos).to eq(0)
  end

  it '#scan, #reset' do
    s = new_scanner(' a')
    expect(s.scan(/a/)).to eq('a')
    expect(s.pos).to eq(2)

    s.reset
    expect(s.pos).to eq(0)
    expect(s.scan(/b/)).to be_nil
    expect(s.pos).to eq(0)

    s = new_scanner(" %comment\na")
    expect(s.scan(/a/)).to eq('a')
    expect(s.pos).to eq(11)

    s.reset
    expect(s.scan(/b/)).to be_nil
    expect(s.pos).to eq(0)
  end

  it '#eos' do
    expect(new_scanner('')).to be_eos
    expect(new_scanner(' ')).to be_eos
    expect(new_scanner(" %test\n%test")).to be_eos
    expect(new_scanner(' a')).not_to be_eos
    expect(new_scanner(' \\command')).not_to be_eos
  end

  it '#check_command' do
    expect('\t').to eq('\\t')

    expect(new_scanner('test').check_command).to be_nil
    s = new_scanner(' \test')
    expect(s.check_command).to eq('\\test')
    expect(s[1]).to eq('test')

    expect(new_scanner(' \test next').check_command).to eq('\test')
    expect(new_scanner(' \test_a').check_command).to eq('\test')
  end

  it '#scan_command' do
    expect(new_scanner('test').scan_command).to be_nil

    s = new_scanner(' \test')
    expect(s.scan_command).to eq('\test')
    expect(s[1]).to eq('test')
    expect(s.pos).to eq(6)

    s = new_scanner(' \test rest')
    expect(s.scan_command).to eq('\test')
    expect(s.pos).to eq(6)

    s = new_scanner(' \test_a')
    expect(s.scan_command).to eq('\test')
    expect(s.pos).to eq(6)

    s = new_scanner(' \_test')
    expect(s.check_command).to eq('\_')
    expect(s.scan_command).to eq('\_')
    expect(s.rest).to eq('test')
  end

  it '#scan_block' do
    expect(new_scanner(' a').scan_block).to be_nil
    expect(new_scanner(' a').check_block).to be_nil

    i = ' {{}{}{{}{}}} '
    e = "{#{i}}"
    s = new_scanner(" #{e} test")
    expect(s.check_block).to eq(e)
    expect(s.matched).to eq(e)
    expect(s[1]).to eq(i)
    expect(s.scan_block).to eq(e)
    expect(s.matched).to eq(e)
    expect(s[1]).to eq(i)
    expect(s.rest).to eq(' test')

    expect(new_scanner(' \command test').scan_block).to be_nil
    expect(new_scanner(' \command test').check_block).to be_nil

    expect(new_scanner('').scan_block).to be_nil
    expect(new_scanner('').check_block).to be_nil

    expect(new_scanner(' ').scan_block).to be_nil
    expect(new_scanner(' ').check_block).to be_nil

    s = new_scanner('{test')
    expect { s.scan_block }.to raise_error(MathML::LaTeX::BlockNotClosed)
  end

  it '#scan_any' do
    s0 = " %comment\n "
    s1 = '{}'
    s = new_scanner(s0 + s1)
    expect(s.scan_any).to eq(s1)
    s.reset
    expect(s.scan_any(true)).to eq(s0 + s1)
    expect(s.matched).to eq(s1)

    s1 = '\command'
    s = new_scanner(s0 + s1)
    expect(s.scan_any).to eq(s1)
    s.reset
    expect(s.scan_any(true)).to eq(s0 + s1)

    s1 = 'a'
    s = new_scanner(s0 + s1)
    expect(s.scan_any).to eq(s1)
    s.reset
    expect(s.scan_any(true)).to eq(s0 + s1)

    s = new_scanner(' ')
    expect(s.scan_any).to be_nil
    s.reset
    expect(s.scan_any(true)).to eq(' ')

    s = new_scanner('\begin{env}test\end{env}')
    expect(s.scan_any).to eq('\begin')
  end

  it '#peek_command' do
    expect(new_scanner(' \test').peek_command).to eq('test')
    expect(new_scanner('').peek_command).to be_nil
    expect(new_scanner(' ').peek_command).to be_nil
    expect(new_scanner(' a').peek_command).to be_nil
  end

  it '#scan_option' do
    s = new_scanner(' []')
    expect(s.scan_option).to eq('[]')
    expect(s[1]).to eq('')
    expect(s.pos).to eq(3)

    s = new_scanner(' [ opt ]')
    expect(s.scan_option).to eq('[ opt ]')
    expect(s[1]).to eq(' opt ')
    expect(s.pos).to eq(8)

    s = new_scanner(' [[]]')
    expect(s.scan_option).to eq('[[]')
    expect(s[1]).to eq('[')

    s = new_scanner(' [{[]}]')
    expect(s.scan_option).to eq('[{[]}]')
    expect(s[1]).to eq('{[]}')

    expect { new_scanner('[').scan_option }.to raise_error(MathML::LaTeX::OptionNotClosed)
  end

  it '#check_option' do
    s = new_scanner(' []')
    expect(s.check_option).to eq('[]')
    expect(s[1]).to eq('')
    expect(s.pos).to eq(0)

    s = new_scanner(' [ opt ]')
    expect(s.check_option).to eq('[ opt ]')
    expect(s[1]).to eq(' opt ')
    expect(s.pos).to eq(0)

    s = new_scanner(' [[]]')
    expect(s.check_option).to eq('[[]')
    expect(s[1]).to eq('[')

    s = new_scanner(' [{[]}]')
    expect(s.check_option).to eq('[{[]}]')
    expect(s[1]).to eq('{[]}')

    expect { new_scanner('[').check_option }.to raise_error(MathML::LaTeX::OptionNotClosed)
  end
end
