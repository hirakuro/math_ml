require 'spec_util'
require 'eim_xml/parser'
require 'eim_xml/dsl'
require 'math_ml'
require 'math_ml/symbol/character_reference'
require 'math_ml/symbol/utf8'

describe MathML::LaTeX::Parser do
  include MathML::Spec::Util

  def check_chr(tag, src)
    src.scan(/./) do |c|
      tag_re = Regexp.escape(tag)
      expect(smml(c)).to match(%r{\A<#{tag_re}(\s+[^>]+)?>#{Regexp.escape(c)}</#{tag_re}>\z})
    end
  end

  def check_hash(tag, hash)
    hash.each do |k, v|
      tag_re = Regexp.escape(tag)
      expect(smml(k)).to match(%r{\A<#{tag_re}(\s+[^>]+)?>#{Regexp.escape(v)}</#{tag_re}>\z})
    end
  end

  def check_entity(tag, hash)
    check_hash(tag, hash.each_with_object({}) { |i, r| r[i[0]] = "&#{i[1]};"; })
  end

  it 'Spec#strip_math_ml' do
    src = "<math test='dummy'> <a> b </a> <c> d </c></math>"
    expect(strip_math_ml(src)).to eq('<a>b</a><c>d</c>')
  end

  describe '#parse' do
    it 'returns math element' do
      ns = 'http://www.w3.org/1998/Math/MathML'

      e = new_parser.parse('')
      expect(e).to match(EimXML::Element.new(:math, :display => 'inline', 'xmlns' => ns))
      expect(e.attributes.keys.size).to eq(2)
      expect(e.contents).to be_empty

      e = new_parser.parse('', true)
      expect(e).to match(EimXML::Element.new(:math, :display => 'block', 'xmlns' => ns))
      expect(e.attributes.keys.size).to eq(2)
      expect(e.contents).to be_empty

      e = new_parser.parse('', false)
      expect(e).to match(EimXML::Element.new(:math, :display => 'inline', 'xmlns' => ns))
      expect(e.attributes.keys.size).to eq(2)
      expect(e.contents).to be_empty
    end

    it 'ignores space' do
      expect(smml('{ a }')).to eq('<mrow><mi>a</mi></mrow>')
    end

    it 'processes latex block' do
      expect { smml('test {test} {test') }.to raise_parse_error('Block not closed.', 'test {test} ', '{test')
    end

    it 'raises error when error happened' do
      src = 'a\hoge c'
      expect { smml(src) }.to raise_parse_error('Undefined command.', 'a', '\hoge c')

      src = '\sqrt\sqrt1'
      expect { smml(src) }.to raise_parse_error('Syntax error.', '\sqrt\sqrt', '1')

      src = 'a{b'
      expect { smml(src) }.to raise_parse_error('Block not closed.', 'a', '{b')
    end

    it 'processes numerics' do
      expect(smml('1234567890')).to eq('<mn>1234567890</mn>')
      expect(smml('1.2')).to eq('<mn>1.2</mn>')
      expect(smml('1.')).to eq("<mn>1</mn><mo stretchy='false'>.</mo>")
      expect(smml('.2')).to eq('<mn>.2</mn>')
      expect(smml('1.2.3')).to eq('<mn>1.2</mn><mn>.3</mn>')
    end

    it 'processes alphabets' do
      expect(smml('abc')).to eq('<mi>a</mi><mi>b</mi><mi>c</mi>')
      check_chr('mi', 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')
    end

    it 'processes non alphabet command' do
      expect(smml('\|')).to eq("<mo stretchy='false'>&DoubleVerticalBar;</mo>")
    end

    it 'processes space commands' do
      expect(smml('\ ')).to eq("<mspace width='1em' />")
      expect(smml('\quad')).to eq("<mspace width='1em' />")
      expect(smml('\qquad')).to eq("<mspace width='2em' />")
      expect(smml('\,')).to eq("<mspace width='0.167em' />")
      expect(smml('\:')).to eq("<mspace width='0.222em' />")
      expect(smml('\;')).to eq("<mspace width='0.278em' />")
      expect(smml('\!')).to eq("<mspace width='-0.167em' />")
      expect(smml('~')).to eq("<mspace width='1em' />")
    end

    it 'processes operators' do
      check_chr('mo', ',.+-*=/()[]|;:!')
      check_entity('mo', { '<' => 'lt', '>' => 'gt', '"' => 'quot' })
      check_hash('mo', { '\backslash' => '\\', '\%' => '%', '\{' => '{', '\}' => '}', '\$' => '$', '\#' => '#' })
    end

    describe 'should process prime' do
      it 'entity reference' do
        expect(smml("a'")).to eq('<msup><mi>a</mi><mo>&prime;</mo></msup>')
        expect(smml("a''")).to eq('<msup><mi>a</mi><mo>&prime;&prime;</mo></msup>')
        expect(smml("a'''")).to eq('<msup><mi>a</mi><mo>&prime;&prime;&prime;</mo></msup>')
        expect(smml("'")).to eq('<msup><none /><mo>&prime;</mo></msup>')

        expect { smml("a^b'") }.to raise_parse_error('Double superscript.', 'a^b', "'")

        expect(smml("a'^b")).to eq('<msup><mi>a</mi><mrow><mo>&prime;</mo><mi>b</mi></mrow></msup>')
        expect(smml("a'''^b")).to eq('<msup><mi>a</mi><mrow><mo>&prime;&prime;&prime;</mo><mi>b</mi></mrow></msup>')
        expect(smml("a'b")).to eq('<msup><mi>a</mi><mo>&prime;</mo></msup><mi>b</mi>')
      end

      it 'utf8' do
        @parser = MathML::LaTeX::Parser.new(symbol: MathML::Symbol::UTF8)
        expect(smml("a'")).to eq('<msup><mi>a</mi><mo>′</mo></msup>')
        expect(smml("a'''")).to eq('<msup><mi>a</mi><mo>′′′</mo></msup>')
      end

      it 'character reference' do
        @parser = MathML::LaTeX::Parser.new(symbol: MathML::Symbol::CharacterReference)
        expect(smml("a'")).to eq('<msup><mi>a</mi><mo>&#x2032;</mo></msup>')
        expect(smml("a'''")).to eq('<msup><mi>a</mi><mo>&#x2032;&#x2032;&#x2032;</mo></msup>')
      end
    end

    it 'processes sqrt' do
      expect(smml('\sqrt a')).to eq('<msqrt><mi>a</mi></msqrt>')
      expect(smml('\sqrt[2]3')).to eq('<mroot><mn>3</mn><mn>2</mn></mroot>')
      expect(smml('\sqrt[2a]3')).to eq('<mroot><mn>3</mn><mrow><mn>2</mn><mi>a</mi></mrow></mroot>')
      expect { smml('\sqrt[12') }.to raise_parse_error('Option not closed.', '\sqrt', '[12')
    end

    it 'processes subsup' do
      expect(smml('a_b^c')).to eq('<msubsup><mi>a</mi><mi>b</mi><mi>c</mi></msubsup>')
      expect(smml('a_b')).to eq('<msub><mi>a</mi><mi>b</mi></msub>')
      expect(smml('a^b')).to eq('<msup><mi>a</mi><mi>b</mi></msup>')
      expect(smml('_a^b')).to eq('<msubsup><none /><mi>a</mi><mi>b</mi></msubsup>')

      expect { smml('a_b_c') }.to raise_parse_error('Double subscript.', 'a_b', '_c')
      expect { smml('a^b^c') }.to raise_parse_error('Double superscript.', 'a^b', '^c')
      expect { smml('a_') }.to raise_parse_error('Subscript not exist.', 'a_', '')
      expect { smml('a^') }.to raise_parse_error('Superscript not exist.', 'a^', '')
    end

    it 'processes underover' do
      expect(smml('\sum_a^b', true)).to eq("<munderover><mo stretchy='false'>&sum;</mo><mi>a</mi><mi>b</mi></munderover>")
      expect(smml('\sum_a^b')).to eq("<msubsup><mo stretchy='false'>&sum;</mo><mi>a</mi><mi>b</mi></msubsup>")
      expect(smml('\sum_a', true)).to eq("<munder><mo stretchy='false'>&sum;</mo><mi>a</mi></munder>")
      expect(smml('\sum^a', true)).to eq("<mover><mo stretchy='false'>&sum;</mo><mi>a</mi></mover>")
      expect(smml('\sum_a')).to eq("<msub><mo stretchy='false'>&sum;</mo><mi>a</mi></msub>")
      expect(smml('\sum^a')).to eq("<msup><mo stretchy='false'>&sum;</mo><mi>a</mi></msup>")

      expect { smml('\sum_b_c') }.to raise_parse_error('Double subscript.', '\sum_b', '_c')
      expect { smml('\sum^b^c') }.to raise_parse_error('Double superscript.', '\sum^b', '^c')
      expect { smml('\sum_') }.to raise_parse_error('Subscript not exist.', '\sum_', '')
      expect { smml('\sum^') }.to raise_parse_error('Superscript not exist.', '\sum^', '')
    end

    it 'processes font commands' do
      expect(smml('a{\bf b c}d')).to eq("<mi>a</mi><mrow><mi mathvariant='bold'>b</mi><mi mathvariant='bold'>c</mi></mrow><mi>d</mi>")
      expect(smml('\bf a{\it b c}d')).to eq("<mi mathvariant='bold'>a</mi><mrow><mi>b</mi><mi>c</mi></mrow><mi mathvariant='bold'>d</mi>")
      expect(smml('a{\rm b c}d')).to eq("<mi>a</mi><mrow><mi mathvariant='normal'>b</mi><mi mathvariant='normal'>c</mi></mrow><mi>d</mi>")

      expect(smml('a \mathbf{bc}d')).to eq("<mi>a</mi><mrow><mrow><mi mathvariant='bold'>b</mi><mi mathvariant='bold'>c</mi></mrow></mrow><mi>d</mi>")
      expect(smml('\mathbf12')).to eq("<mrow><mn mathvariant='bold'>1</mn></mrow><mn>2</mn>")
      expect(smml('\bf a \mathit{bc} d')).to eq("<mi mathvariant='bold'>a</mi><mrow><mrow><mi>b</mi><mi>c</mi></mrow></mrow><mi mathvariant='bold'>d</mi>")
      expect(smml('a\mathrm{bc}d')).to eq("<mi>a</mi><mrow><mrow><mi mathvariant='normal'>b</mi><mi mathvariant='normal'>c</mi></mrow></mrow><mi>d</mi>")

      expect(smml('a \mathbb{b c} d')).to eq('<mi>a</mi><mrow><mrow><mi>&bopf;</mi><mi>&copf;</mi></mrow></mrow><mi>d</mi>')
      expect(smml('a \mathscr{b c} d')).to eq('<mi>a</mi><mrow><mrow><mi>&bscr;</mi><mi>&cscr;</mi></mrow></mrow><mi>d</mi>')
      expect(smml('a \mathfrak{b c} d')).to eq('<mi>a</mi><mrow><mrow><mi>&bfr;</mi><mi>&cfr;</mi></mrow></mrow><mi>d</mi>')
      expect(smml('a \bm{bc}d')).to eq("<mi>a</mi><mrow><mrow><mi mathvariant='bold-italic'>b</mi><mi mathvariant='bold-italic'>c</mi></mrow></mrow><mi>d</mi>")
      expect(smml('\bm ab')).to eq("<mrow><mi mathvariant='bold-italic'>a</mi></mrow><mi>b</mi>")

      expect { smml('\mathit') }.to raise_parse_error('Syntax error.', '\mathit', '')
      expect { smml('\mathrm') }.to raise_parse_error('Syntax error.', '\mathrm', '')
      expect { smml('\mathbf') }.to raise_parse_error('Syntax error.', '\mathbf', '')
      expect { smml('\mathbb') }.to raise_parse_error('Syntax error.', '\mathbb', '')
      expect { smml('\mathscr') }.to raise_parse_error('Syntax error.', '\mathscr', '')
      expect { smml('\mathfrak') }.to raise_parse_error('Syntax error.', '\mathfrak', '')
    end

    it 'processes mbox' do
      expect(smml('a\mbox{b c}d')).to eq('<mi>a</mi><mtext>b c</mtext><mi>d</mi>')
      expect(smml('\mbox{<>\'"&}')).to eq('<mtext>&lt;&gt;&apos;&quot;&amp;</mtext>')
    end

    it 'processes frac' do
      expect(smml('\frac ab')).to eq('<mfrac><mi>a</mi><mi>b</mi></mfrac>')
      expect(smml('\frac12')).to eq('<mfrac><mn>1</mn><mn>2</mn></mfrac>')

      expect { smml('\frac a') }.to raise_parse_error('Syntax error.', '\frac a', '')
    end

    it 'processes environment' do
      expect { smml('{\begin}rest') }.to raise_parse_error('Environment name not exist.', '{\begin', '}rest')

      expect { smml('{\begin{array}{c}dummy}rest') }.to raise_parse_error('Matching \end not exist.', '{\begin{array}{c}dummy', '}rest')

      expect { smml('\begin{array}c dummy\end{test}') }.to raise_parse_error('Environment mismatched.', '\begin{array}c dummy\end', '{test}')

      expect { smml('\left(\begin{array}\right)') }.to raise_parse_error('Syntax error.', '\left(\begin{array}', '\right)')
    end

    it 'processes array' do
      expect(smml('\begin{array}{lrc} a & b & c \\\\ d & e & f \\\\ \end{array}')).to eq("<mtable columnalign='left right center'><mtr><mtd><mi>a</mi></mtd><mtd><mi>b</mi></mtd><mtd><mi>c</mi></mtd></mtr><mtr><mtd><mi>d</mi></mtd><mtd><mi>e</mi></mtd><mtd><mi>f</mi></mtd></mtr></mtable>")

      expect(smml('\begin{array}{lrc}a&b&c\\\\d&e&f \end{array}')).to eq("<mtable columnalign='left right center'><mtr><mtd><mi>a</mi></mtd><mtd><mi>b</mi></mtd><mtd><mi>c</mi></mtd></mtr><mtr><mtd><mi>d</mi></mtd><mtd><mi>e</mi></mtd><mtd><mi>f</mi></mtd></mtr></mtable>")

      expect(smml('\begin{array}{c}\end{array}')).to eq('<mtable />')

      expect { smml('\begin{array}\end{array}') }.to raise_parse_error('Syntax error.', '\begin{array}', '\end{array}')

      expect { smml('\begin{array}{a}\end{array}') }.to raise_parse_error('Syntax error.', '\begin{array}{', 'a}\end{array}')

      expect { smml('\begin{array}{cc}a\\\\b&c\end{array}') }.to raise_parse_error('Need more column.', '\begin{array}{cc}a', '\\\\b&c\end{array}')

      expect { smml('\begin{array}{cc}a\end{array}') }.to raise_parse_error('Need more column.', '\begin{array}{cc}a', '\end{array}')

      expect { smml('\begin{array}{c}a&\end{array}') }.to raise_parse_error('Too many column.', '\begin{array}{c}a', '&\end{array}')

      expect(smml('\begin{array}{cc}&\end{array}')).to eq('<mtable><mtr><mtd /><mtd /></mtr></mtable>')

      expect(math_ml('\left\{\begin{array}ca_b\end{array}\right\}')[0]).to match(EimXML::DSL.element(:mfenced, open: '{', close: '}') do
        element :mrow do
          element :mtable do
            element :mtr do
              element :mtd do
                element :msub do
                  element(:mi).add('a')
                  element(:mi).add('b')
                end
              end
            end
          end
        end
      end)

      expect(smml('\begin{array}{@{a_1}l@bc@cr@d}A&B&C\end{array}')).to eq("<mtable columnalign='center left center center center right center'><mtr><mtd><mrow><msub><mi>a</mi><mn>1</mn></msub></mrow></mtd><mtd><mi>A</mi></mtd><mtd><mi>b</mi></mtd><mtd><mi>B</mi></mtd><mtd><mi>c</mi></mtd><mtd><mi>C</mi></mtd><mtd><mi>d</mi></mtd></mtr></mtable>")

      expect(math_ml('\left\{\begin{array}ca_b\end{array}\right\}')[0]).to match(EimXML::DSL.element(:mfenced, open: '{', close: '}') do
        element :mrow do
          element :mtable do
            element :mtr do
              element :mtd do
                element :msub do
                  element(:mi).add('a')
                  element(:mi).add('b')
                end
              end
            end
          end
        end
      end)

      expect(smml('\begin{array}{c|c}a&b\\\\c&d\end{array}')).to eq("<mtable columnlines='solid'><mtr><mtd><mi>a</mi></mtd><mtd><mi>b</mi></mtd></mtr><mtr><mtd><mi>c</mi></mtd><mtd><mi>d</mi></mtd></mtr></mtable>")
      expect(smml('\begin{array}{|c|}a\\\\c\end{array}')).to eq("<mtable columnlines='solid solid'><mtr><mtd /><mtd><mi>a</mi></mtd><mtd /></mtr><mtr><mtd /><mtd><mi>c</mi></mtd><mtd /></mtr></mtable>")
      expect(smml('\begin{array}{c}\hline c\end{array}')).to eq("<mtable rowlines='solid'><mtr /><mtr><mtd><mi>c</mi></mtd></mtr></mtable>")
      expect(smml('\begin{array}{c@acc}c&c&c\\\\\hline\end{array}')).to eq("<mtable rowlines='solid'><mtr><mtd><mi>c</mi></mtd><mtd><mi>a</mi></mtd><mtd><mi>c</mi></mtd><mtd><mi>c</mi></mtd></mtr><mtr><mtd /><mtd /><mtd /><mtd /></mtr></mtable>")
      expect(smml('\begin{array}{c}\hline a\\\\b\\\\\hline\end{array}')).to eq("<mtable rowlines='solid none solid'><mtr /><mtr><mtd><mi>a</mi></mtd></mtr><mtr><mtd><mi>b</mi></mtd></mtr><mtr><mtd /></mtr></mtable>")
    end

    it 'parses \left and \right' do
      expect(math_ml('\left(\frac12\right)')[0]).to match(EimXML::DSL.element(:mfenced, open: '(', close: ')') do
        element :mrow do
          element :mfrac do
            element(:mn).add('1')
            element(:mn).add('2')
          end
        end
      end)

      expect(math_ml('\left \lfloor a\right \rfloor')[0]).to match(EimXML::DSL.element(:mfenced, open: EimXML::PCString.new('&lfloor;', true), close: EimXML::PCString.new('&rfloor;', true)) do
        element :mrow do
          element(:mi).add('a')
        end
      end)

      expect(math_ml('\left \{ a \right \}')[0]).to match(EimXML::DSL.element(:mfenced, open: '{', close: '}') do
        element :mrow do
          element(:mi).add('a')
        end
      end)

      expect(math_ml('\left\{\begin{array}c\begin{array}ca\end{array}\end{array}\right\}')[0]).to match(EimXML::DSL.element(:mfenced, open: '{', close: '}') do
        element :mrow do
          element :mtable do
            element :mtr do
              element :mtd do
                element :mtable do
                  element :mtr do
                    element :mtd do
                      element(:mi).add('a')
                    end
                  end
                end
              end
            end
          end
        end
      end)

      expect(math_ml('\left(\sum_a\right)')[0]).to match(EimXML::DSL.element(:mfenced, open: '(', close: ')') do
        element :mrow do
          element :msub do
            element(:mo).add(EimXML::PCString.new('&sum;', true))
            element(:mi).add('a')
          end
        end
      end)

      expect(math_ml('\left(\sum_a\right)', true)[0]).to match(EimXML::DSL.element(:mfenced, open: '(', close: ')') do
        element :mrow do
          element :munder do
            element(:mo).add(EimXML::PCString.new('&sum;', true))
            element(:mi).add('a')
          end
        end
      end)

      expect { smml('\left(test') }.to raise_parse_error('Brace not closed.', '\left', '(test')

      expect(math_ml('\left\|a\right\|')[0]).to match(EimXML::DSL.element(:mfenced, open: EimXML::PCString.new('&DoubleVerticalBar;', true), close: EimXML::PCString.new('&DoubleVerticalBar;', true)) do
        element :mrow do
          element(:mi).add('a')
        end
      end)

      expect { smml('\left') }.to raise_parse_error('Need brace here.', '\left', '')
    end

    it 'parses overs' do
      expect(smml('\hat a')).to eq('<mover><mi>a</mi><mo>&circ;</mo></mover>')
      expect(smml('\hat12')).to eq('<mover><mn>1</mn><mo>&circ;</mo></mover><mn>2</mn>')
      expect { smml('{\hat}a') }.to raise_parse_error('Syntax error.', '{\hat', '}a')
    end

    it 'parses unders' do
      expect(smml('\underline a')).to eq('<munder><mi>a</mi><mo>&macr;</mo></munder>')
      expect(smml('\underline12')).to eq('<munder><mn>1</mn><mo>&macr;</mo></munder><mn>2</mn>')
      expect { smml('{\underline}a') }.to raise_parse_error('Syntax error.', '{\underline', '}a')
    end

    it 'parses stackrel' do
      expect(smml('\stackrel\to=')).to eq("<mover><mo stretchy='false'>=</mo><mo stretchy='false'>&rightarrow;</mo></mover>")
      expect(smml('\stackrel12')).to eq('<mover><mn>2</mn><mn>1</mn></mover>')
    end

    it 'parses comment' do
      expect(smml('a%b')).to eq('<mi>a</mi>')
    end

    it 'parses entity' do
      p = new_parser
      expect { smml('\entity{therefore}', false, p) }.to raise_parse_error('Unregistered entity.', '\entity{', 'therefore}')

      p.unsecure_entity = true
      expect(smml('\entity{therefore}', false, p)).to eq('<mo>&therefore;</mo>')

      p.unsecure_entity = false
      expect { smml('\entity{therefore}', false, p) }.to raise_parse_error('Unregistered entity.', '\entity{', 'therefore}')

      p.add_entity(['therefore'])
      expect(smml('\entity{therefore}', false, p)).to eq('<mo>&therefore;</mo>')
    end

    it 'parses backslash' do
      expect(smml('\\\\')).to eq("<br xmlns='http://www.w3.org/1999/xhtml' />")
    end

    it 'can be used with macro' do
      macro = <<~'EOS'
        \newcommand{\root}[2]{\sqrt[#1]{#2}}
        \newcommand{\ROOT}[2]{\sqrt[#1]#2}
        \newenvironment{braced}[2]{\left#1}{\right#2}
        \newenvironment{sq}[2]{\sqrt[#2]{#1}}{\sqrt#2}
        \newcommand{\R}{\mathbb R}
        \newenvironment{BB}{\mathbb A}{\mathbb B}
      EOS
      p = new_parser
      p.macro.parse(macro)

      expect(smml('\root12', false, p)).to eq('<mroot><mrow><mn>2</mn></mrow><mn>1</mn></mroot>')
      expect(smml('\root{12}{34}', false, p)).to eq('<mroot><mrow><mn>34</mn></mrow><mn>12</mn></mroot>')
      expect(smml('\ROOT{12}{34}', false, p)).to eq('<mroot><mn>3</mn><mn>12</mn></mroot><mn>4</mn>')
      expect { smml('\root', false, p) }.to raise_parse_error('Error in macro(Need more parameter. "").', '', '\root')

      expect(math_ml('\begin{braced}{|}{)}\frac12\end{braced}', false, p)[0]).to match(EimXML::DSL.element(:mfenced, open: '|', close: ')') do
        element(:mrow) do
          element(:mfrac) do
            element(:mn).add('1')
            element(:mn).add('2')
          end
        end
      end)

      expect(smml('\begin{sq}{12}{34}a\end{sq}', false, p)).to eq('<mroot><mrow><mn>12</mn></mrow><mn>34</mn></mroot><mi>a</mi><msqrt><mn>3</mn></msqrt><mn>4</mn>')
      expect { smml('\begin{braced}', false, p) }.to raise_parse_error('Need more parameter.', '\begin{braced}', '')
      expect { smml('\begin{braced}123', false, p) }.to raise_parse_error('Matching \end not exist.', '\begin{braced}', '123')
      expect { smml('\begin{braced}123\end{brace}', false, p) }.to raise_parse_error('Environment mismatched.', '\begin{braced}123\end', '{brace}')
      expect(smml('\R', false, p)).to eq('<mrow><mi>&Ropf;</mi></mrow>')
      expect(smml('\begin{BB}\end{BB}', false, p)).to eq('<mrow><mi>&Aopf;</mi></mrow><mrow><mi>&Bopf;</mi></mrow>')
    end

    it 'raises error when macro define circular reference' do
      macro = <<~'EOT'
        \newcommand{\C}{\C}
        \newenvironment{E}{\begin{E}}{\end{E}}
        \newcommand{\D}{\begin{F}\end{F}}
        \newenvironment{F}{\D}{}
      EOT
      ps = new_parser
      ps.macro.parse(macro)

      expect { smml('\C', false, ps) }.to raise_parse_error('Circular reference.', '', '\C')
      expect { smml('\begin{E}\end{E}', false, ps) }.to raise_parse_error('Circular reference.', '', '\begin{E}\end{E}')
      expect { smml('\D', false, ps) }.to raise_parse_error('Circular reference.', '', '\D')
      expect { smml('\begin{F}\end{F}', false, ps) }.to raise_parse_error('Circular reference.', '', '\begin{F}\end{F}')
    end

    it 'raises error when macro uses undefined command' do
      macro = <<~'EOT'
        \newcommand{\C}{\dummy}
        \newenvironment{E}{\dummy}{}
      EOT
      ps = new_parser
      ps.macro.parse(macro)

      expect { smml('\C', false, ps) }.to raise_parse_error('Error in macro(Undefined command. "\dummy").', '', '\C')
      expect { smml('\C', false, ps) }.to raise_parse_error('Error in macro(Undefined command. "\dummy").', '', '\C')

      expect { smml('\begin{E}\end{E}', false, ps) }.to raise_parse_error('Error in macro(Undefined command. "\dummy").', '', '\begin{E}\end{E}')
      expect { smml('\begin{E}\end{E}', false, ps) }.to raise_parse_error('Error in macro(Undefined command. "\dummy").', '', '\begin{E}\end{E}')
    end

    it 'can be used with macro with option' do
      macro = <<~'EOS'
        \newcommand{\opt}[1][x]{#1}
        \newcommand{\optparam}[2][]{#1#2}
        \newenvironment{newenv}[1][x]{#1}{#1}
        \newenvironment{optenv}[2][]{#1}{#2}
      EOS

      p = new_parser
      p.macro.parse(macro)

      expect(smml('\opt a', false, p)).to eq('<mi>x</mi><mi>a</mi>')
      expect(smml('\opt[0] a', false, p)).to eq('<mn>0</mn><mi>a</mi>')
      expect(smml('\optparam a', false, p)).to eq('<mi>a</mi>')
      expect(smml('\optparam[0] a', false, p)).to eq('<mn>0</mn><mi>a</mi>')

      expect(smml('\begin{newenv}a\end{newenv}', false, p)).to eq('<mi>x</mi><mi>a</mi><mi>x</mi>')
      expect(smml('\begin{newenv}[0]a\end{newenv}', false, p)).to eq('<mn>0</mn><mi>a</mi><mn>0</mn>')
      expect(smml('\begin{optenv}0a\end{optenv}', false, p)).to eq('<mi>a</mi><mn>0</mn>')
      expect(smml('\begin{optenv}[0]1a\end{optenv}', false, p)).to eq('<mn>0</mn><mi>a</mi><mn>1</mn>')
    end

    it 'parses matrix environment' do
      expect(smml('\begin{matrix}&&\\\\&\end{matrix}')).to eq('<mtable><mtr><mtd /><mtd /><mtd /></mtr><mtr><mtd /><mtd /></mtr></mtable>')
      expect { smml('\begin{matrix}&&\\\\&\end{mat}') }.to raise_parse_error('Environment mismatched.', '\begin{matrix}&&\\\\&\end', '{mat}')
      expect { smml('\begin{matrix}&&\\\\&') }.to raise_parse_error('Matching \\end not exist.', '\begin{matrix}&&\\\\&', '')
      expect(smml('\begin{matrix}\begin{matrix}a&b\\\\c&d\end{matrix}&1\\\\0&1\\\\\end{matrix}')).to eq('<mtable><mtr><mtd><mtable><mtr><mtd><mi>a</mi></mtd><mtd><mi>b</mi></mtd></mtr><mtr><mtd><mi>c</mi></mtd><mtd><mi>d</mi></mtd></mtr></mtable></mtd><mtd><mn>1</mn></mtd></mtr><mtr><mtd><mn>0</mn></mtd><mtd><mn>1</mn></mtd></mtr></mtable>')
      expect(smml('\begin{matrix}\end{matrix}')).to eq('<mtable />')
      expect(smml('\begin{matrix}\hline a\\\\b\\\\\hline\end{matrix}')).to eq("<mtable rowlines='solid none solid'><mtr /><mtr><mtd><mi>a</mi></mtd></mtr><mtr><mtd><mi>b</mi></mtd></mtr><mtr /></mtable>")

      expect(smml('\begin{smallmatrix}\end{smallmatrix}')).to eq('<mtable />')
      expect(math_ml('\begin{pmatrix}\end{pmatrix}')[0]).to match(EimXML::Element.new(:mfenced, open: '(', close: ')'))
      expect(math_ml('\begin{bmatrix}\end{bmatrix}')[0]).to match(EimXML::Element.new(:mfenced, open: '[', close: ']'))
      expect(math_ml('\begin{Bmatrix}\end{Bmatrix}')[0]).to match(EimXML::Element.new(:mfenced, open: '{', close: '}'))
      expect(math_ml('\begin{vmatrix}\end{vmatrix}')[0]).to match(EimXML::Element.new(:mfenced, open: '|', close: '|'))
      expect(math_ml('\begin{Vmatrix}\end{Vmatrix}')[0]).to match(EimXML::Element.new(:mfenced, open: EimXML::PCString.new('&DoubleVerticalBar;', true), close: EimXML::PCString.new('&DoubleVerticalBar;', true)))
    end

    it 'parses symbols' do
      expect(smml('\precneqq')).to eq("<mo stretchy='false'>&#x2ab5;</mo>")
    end
  end

  describe '.new should accept symbol table' do
    it 'character reference' do
      @parser = MathML::LaTeX::Parser.new(symbol: MathML::Symbol::CharacterReference)
      expect(smml('\alpha')).to eq('<mi>&#x3b1;</mi>')
      expect(smml('\mathbb{abcABC}')).to eq('<mrow><mrow><mi>&#x1d552;</mi><mi>&#x1d553;</mi><mi>&#x1d554;</mi><mi>&#x1d538;</mi><mi>&#x1d539;</mi><mi>&#x2102;</mi></mrow></mrow>')
      expect(smml('\mathscr{abcABC}')).to eq('<mrow><mrow><mi>&#x1d4b6;</mi><mi>&#x1d4b7;</mi><mi>&#x1d4b8;</mi><mi>&#x1d49c;</mi><mi>&#x212c;</mi><mi>&#x1d49e;</mi></mrow></mrow>')
      expect(smml('\mathfrak{abcABC}')).to eq('<mrow><mrow><mi>&#x1d51e;</mi><mi>&#x1d51f;</mi><mi>&#x1d520;</mi><mi>&#x1d504;</mi><mi>&#x1d505;</mi><mi>&#x212d;</mi></mrow></mrow>')
    end

    it 'utf8' do
      @parser = MathML::LaTeX::Parser.new(symbol: MathML::Symbol::UTF8)
      expect(smml('\alpha')).to eq('<mi>α</mi>')
      expect(smml('\mathbb{abcABC}')).to eq('<mrow><mrow><mi>𝕒</mi><mi>𝕓</mi><mi>𝕔</mi><mi>𝔸</mi><mi>𝔹</mi><mi>ℂ</mi></mrow></mrow>')
      expect(smml('\mathscr{abcABC}')).to eq('<mrow><mrow><mi>𝒶</mi><mi>𝒷</mi><mi>𝒸</mi><mi>𝒜</mi><mi>ℬ</mi><mi>𝒞</mi></mrow></mrow>')
      expect(smml('\mathfrak{abcABC}')).to eq('<mrow><mrow><mi>𝔞</mi><mi>𝔟</mi><mi>𝔠</mi><mi>𝔄</mi><mi>𝔅</mi><mi>ℭ</mi></mrow></mrow>')
    end
  end

  describe '#symbol_table' do
    it 'returns when .new was given name of symbol-module' do
      ps = MathML::LaTeX::Parser
      symbol = MathML::Symbol

      expect(ps.new(symbol: symbol::UTF8).symbol_table).to eq(symbol::UTF8)
      expect(ps.new(symbol: symbol::EntityReference).symbol_table).to eq(symbol::EntityReference)
      expect(ps.new(symbol: symbol::CharacterReference).symbol_table).to eq(symbol::CharacterReference)

      expect(ps.new(symbol: :utf8).symbol_table).to eq(symbol::UTF8)
      expect(ps.new(symbol: :entity).symbol_table).to eq(symbol::EntityReference)
      expect(ps.new(symbol: :character).symbol_table).to eq(symbol::CharacterReference)

      expect(ps.new.symbol_table).to eq(symbol::EntityReference)
      expect(ps.new(symbol: nil).symbol_table).to eq(symbol::EntityReference)
    end

    context 'should return default symbol module' do
      math_ml = nil
      loaded_features = nil

      before do
        loaded_features = $LOADED_FEATURES.dup
        $LOADED_FEATURES.delete_if { |i| i =~ /math_ml/ }
        if ::Object.const_defined?(:MathML)
          math_ml = ::Object.const_get(:MathML)
          ::Object.module_eval { remove_const(:MathML) }
        end
      end

      after do
        $LOADED_FEATURES.clear
        $LOADED_FEATURES.push(loaded_features.shift) until loaded_features.empty?
        if math_ml
          ::Object.module_eval { remove_const(:MathML) }
          ::Object.const_set(:MathML, math_ml)
        end
      end

      it 'character entity reference version by default' do
        expect(require('math_ml')).to be true
        expect(MathML::LaTeX::Parser.new.symbol_table).to eq(MathML::Symbol::EntityReference)
      end

      describe 'character entity reference version when set by requiring' do
        it do
          expect(require('math_ml/symbol/entity_reference')).to be true
          expect(MathML::LaTeX::Parser.new.symbol_table).to eq(MathML::Symbol::EntityReference)
        end
      end

      describe 'utf8 version when set by requiring' do
        it do
          expect(require('math_ml/symbol/utf8')).to be true
          expect(MathML::LaTeX::Parser.new.symbol_table).to eq(MathML::Symbol::UTF8)
        end
      end

      describe 'numeric character reference version when set by requiring' do
        it do
          expect(require('math_ml/symbol/character_reference')).to be true
          expect(MathML::LaTeX::Parser.new.symbol_table).to eq(MathML::Symbol::CharacterReference)
        end
      end
    end
  end
end
