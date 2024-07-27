require 'symbols/fetch_symbol'
require 'math_ml'
require 'spec/util'

describe 'Misc' do
  it 'brace_nest' do
    brace_nest('{{}}').should == '{1.{2.}2.}1.'
    brace_nest('{{}{}}').should == '{1.{2.}2.{2.}2.}1.'
  end
end

describe 'Fetch Symbol' do
  include MathML::Spec::Util

  before(:all) do
    @list = <<~'EOT'
      \{ subsup o-
      \& subsup o:amp
      \varepsilon subsup I:
      \Gamma subsup i:
      \ensuremath subsup v
      \log subsup i-
      \lim underover i-
      \dagger subsup #
      \braceld subsup o=x25dc # dummy
      \relbar subsup o--
      \precneqq subsup o-<mfrac mathsize='1%' linethickness='0'><mo>&prec;</mo><mo>&ne;</mo></mfrac>	 # dummy
    EOT
  end

  it 'fetch_symbol' do
    r = fetch_symbol

    # latex.ltx
    r['\\log'].should == :subsup
    r['\\deg'].should == :subsup
    r['\\lim'].should == :underover
    r['\\gcd'].should == :underover
    r['\\bigl'].should.nil?
    r['\\$'].should == :subsup
    r['\\}'].should == :subsup
    r['\\copyright'].should == :subsup
    r['\\%'].should == :subsup

    # fontmath.ltx
    r['\\alpha'].should == :subsup
    r['\\Gamma'].should == :subsup
    r['\\coprod'].should == :underover
    r['\\triangleleft'].should == :subsup
    r['\\propto'].should == :subsup
    r['\\ldotp'].should == :subsup
    r['\\hbar'].should == :subsup
    r['\\overrightarrow'].should.nil?
    r['\\n@space'].should.nil?
    r['\\rightarrowfill'].should.nil?
    r['\\lnot'].should == :subsup
    r['\\|'].should == :subsup
    r['\\lmoustache'].should == :subsup
    r['\\arrowvert'].should == :subsup
    r['\\uparrow'].should == :subsup
    r['\\longleftarrow'].should == :subsup

    # amssymb.sty
    r['\\boxdot'].should == :subsup
    r['\\Doteq'].should == :subsup
    r['\\Diamond'].should == :subsup

    # amsfonts.sty
    r['\\ulcorner'].should == :subsup
    r['\\urcorner'].should == :subsup
    r['\\rightleftharpoons'].should == :subsup
    r['\\leadsto'].should == :subsup
    r['\\dabar@'].should.nil?

    # amsmath.str
    r['\\ldots'].should == :subsup
  end

  it 'parse_list' do
    h = parse_list(@list)[1]
    h['\\{'].should == [:s, :o, '']
    h['\\&'].should == %i[s o amp]
    h['\\varepsilon'].should == %i[s I]
    h['\\Gamma'].should == %i[s i]
    h['\\ensuremath'].should.nil?
    h['\\log'].should == [:s, :i, '']
    h['\\lim'].should == [:u, :i, '']
    h['\\dagger'].should == [:s]
    h['\\braceld'].should == [:s, :o, 0x25dc]
    h['\\relbar'].should == [:s, :o, '-']
    h['\\precneqq'].should == [:s, :o, "<mfrac mathsize='1%' linethickness='0'><mo>&prec;</mo><mo>&ne;</mo></mfrac>"]
  end

  def tm(com, h)
    to_mathml(com, h[com])
  end

  it 'to_mathml' do
    h = parse_list(@list)[1]
    tm('\\{', h).should == '<mo>{</mo>'
    tm('\\&', h).should == '<mo>&amp;</mo>'
    tm('\\varepsilon', h).should == '<mi>&varepsilon;</mi>'
    tm('\\Gamma', h).should == "<mi mathvariant='normal'>&Gamma;</mi>"
    tm('\\ensuremat', h).should == ''
    tm('\\log', h).should == '<mi>log</mi>'
    tm('\\dagger', h).should == '<mo>&dagger;</mo>'
    tm('\\braceld', h).should == '<mo>&#x25dc;</mo>'
  end

  it 'gen_rb' do
    e = <<~'EOT'
      SymbolCommands={
      "{"=>[:s,:o,""],
      "&"=>[:s,:o,:amp],
      "varepsilon"=>[:s,:I],
      "Gamma"=>[:s,:i],
      "ensuremath"=>nil,
      "log"=>[:s,:i,""],
      "lim"=>[:u,:i,""],
      "dagger"=>[:s],
      "braceld"=>[:s,:o,0x25dc],
      "relbar"=>[:s,:o,"-"],
      "precneqq"=>[:s,:o,"<mfrac mathsize='1%' linethickness='0'><mo>&prec;</mo><mo>&ne;</mo></mfrac>"],
      }
    EOT
    gen_rb(@list).should == e
  end

  it 'tes_mathml_rb_symbol_command' do
    a, h = parse_list(IO.read('symbols/list.txt'))
    a.each do |com|
      latex = "#{com}_a^b"
      m = to_mathml(com, h[com])
      if h[com]
        if h[com][0] && h[com][0] == :u
          e = "<munderover>#{m}<mi>a</mi><mi>b</mi></munderover>"
        elsif h[com][0] && h[com][0] == :s
          e = "<msubsup>#{m}<mi>a</mi><mi>b</mi></msubsup>"
        else
          raise com.to_s
        end
      else
        e = case com
            when '\\,'
              "<msubsup><mspace width='0.167em' /><mi>a</mi><mi>b</mi></msubsup>"
            else
              '<msubsup><none /><mi>a</mi><mi>b</mi></msubsup>'
            end
      end
      begin
        -> { smml(latex, true) }.should_not raise_error
        smml(latex, true).should == e
      rescue StandardError
        puts latex
        raise
      end
    end
  end

  it 'delims' do
    d = []
    fetch_symbol(d)

    MathML::LaTeX::BuiltinCommands::Delimiters.each do |i|
      d.should be_include("\\#{i}")
      #			assert(d.include?("\\#{i}"), "Add '#{i}'")
    end
    d.each do |i|
      MathML::LaTeX::BuiltinCommands::Delimiters.should be_include(i[/^\\(.*)$/, 1])
      #			assert(MathML::LaTeX::BuiltinCommands::Delimiters.include?(i[/^\\(.*)$/, 1]), "Missing '#{i}'")
    end
  end

  it 'missing' do
    p = load_preput_list(IO.read('symbols/list.txt'))
    h = fetch_symbol
    p.each_key do |k|
      test = h.include?(k) ? '' : k
      test.should == ''
    end
  end
end
