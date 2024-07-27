require 'math_ml/util'
require 'eim_xml/parser'

describe MathML::Util do
  include MathML::Util

  it '#escapeXML' do
    expect(escapeXML("<>&\"'")).to eq('&lt;&gt;&amp;&quot;&apos;')
    expect(escapeXML("\n")).to eq("\n")
    expect(escapeXML("\n", true)).to eq("<br />\n")
  end

  it '.escapeXML' do
    expect(MathML::Util.escapeXML("<>&\"'")).to eq('&lt;&gt;&amp;&quot;&apos;')
    expect(MathML::Util.escapeXML("\n")).to eq("\n")
    expect(MathML::Util.escapeXML("\n", true)).to eq("<br />\n")
  end

  it '#collect_regexp' do
    expect(collect_regexp([/a/, /b/, /c/])).to eq(/#{/a/}|#{/b/}|#{/c/}/)
    expect(collect_regexp([[/a/, /b/, /c/]])).to eq(/#{/a/}|#{/b/}|#{/c/}/)
    expect(collect_regexp([])).to eq(/(?!)/)
    expect(collect_regexp(/a/)).to eq(/#{/a/}/)
  end

  it '.collect_regexp' do
    expect(MathML::Util.collect_regexp([/a/, /b/, /c/])).to eq(/#{/a/}|#{/b/}|#{/c/}/)
    expect(MathML::Util.collect_regexp([[/a/, /b/, /c/]])).to eq(/#{/a/}|#{/b/}|#{/c/}/)
    expect(MathML::Util.collect_regexp([])).to eq(/(?!)/)
    expect(MathML::Util.collect_regexp(/a/)).to eq(/#{/a/}/)

    expect(MathML::Util.collect_regexp([nil, /a/, 'text', /b/])).to eq(/#{/a/}|#{/b/}/)

    expect(MathML::Util.collect_regexp([nil, [/a/, [/b/, /c/]]])).to eq(/#{/a/}|#{/b/}|#{/c/}/)
  end

  it '::INVALID_RE' do
    expect(MathML::Util::INVALID_RE).to eq(/(?!)/)
  end
end

describe MathML::Util::MathData do
  it '#<< and #update' do
    m = MathML::Util::MathData.new
    m.math_list << 'ml1'
    m.msrc_list << 'sl1'
    m.dmath_list << 'dml1'
    m.dsrc_list << 'dsl1'
    m.escape_list << 'el1'
    m.esrc_list << 'es1'
    m.user_list << 'ul1'
    m.usrc_list << 'usl1'
    expect(m.math_list).to eq(['ml1'])
    expect(m.msrc_list).to eq(['sl1'])
    expect(m.dmath_list).to eq(['dml1'])
    expect(m.dsrc_list).to eq(['dsl1'])
    expect(m.escape_list).to eq(['el1'])
    expect(m.esrc_list).to eq(['es1'])
    expect(m.user_list).to eq(['ul1'])
    expect(m.usrc_list).to eq(['usl1'])

    m2 = MathML::Util::MathData.new
    m2.math_list << 'ml2'
    m2.msrc_list << 'sl2'
    m2.dmath_list << 'dml2'
    m2.dsrc_list << 'dsl2'
    m2.escape_list << 'el2'
    m2.esrc_list << 'es2'
    m2.user_list << 'ul2'
    m2.usrc_list << 'usl2'

    m.update(m2)

    expect(m.math_list).to eq(%w[ml1 ml2])
    expect(m.msrc_list).to eq(%w[sl1 sl2])
    expect(m.dmath_list).to eq(%w[dml1 dml2])
    expect(m.dsrc_list).to eq(%w[dsl1 dsl2])
    expect(m.escape_list).to eq(%w[el1 el2])
    expect(m.esrc_list).to eq(%w[es1 es2])
    expect(m.user_list).to eq(%w[ul1 ul2])
    expect(m.usrc_list).to eq(%w[usl1 usl2])
  end
end

describe MathML::Util::SimpleLaTeX do
  def strip_math(s)
    s.gsub(/>\s*/, '>').gsub(/\s*</, '<')[%r{<math.*?>(.*)</math>}m, 1]
  end

  def sma(a) # Stripped Mathml Array
    r = []
    a.each do |i|
      r << strip_math(i.to_s)
    end
    r
  end

  def simplify_math(src)
    attr = []
    r = src.gsub(/<math(\s+[^>]+)>/) do |_m|
      attr << $1.scan(/\s+[^\s]+/).map { |i| i[/\A\s*(.*)/, 1] }.sort
      '<math>'
    end
    attr.unshift(r)
  end

  def assert_data(src,
                  expected_math, expected_src,
                  expected_dmath, expected_dsrc,
                  expected_escaped, expected_esrc,
                  expected_encoded, expected_decoded,
                  simple_latex = MathML::Util::SimpleLaTeX)
    encoded, data = simple_latex.encode(src)

    data.math_list.each do |i|
      expect(i.attributes[:display]).to eq('inline')
    end
    data.dmath_list.each do |i|
      expect(i.attributes[:display]).to eq('block')
    end

    expect(sma(data.math_list)).to eq(expected_math)
    expect(data.msrc_list).to eq(expected_src)
    expect(sma(data.dmath_list)).to eq(expected_dmath)
    expect(data.dsrc_list).to eq(expected_dsrc)
    expect(data.escape_list).to eq(expected_escaped)
    expect(data.esrc_list).to eq(expected_esrc)
    expect(encoded).to eq(expected_encoded)
    target = simple_latex.decode(encoded, data)
    expect(simplify_math(target)).to eq(simplify_math(expected_decoded))
  end

  it '(spec for helper)' do
    expect(simplify_math("<math c='d' a='b'>..</math><math g='h' e='f'></math>")).to eq(['<math>..</math><math></math>', %w[a='b' c='d'], %w[e='f' g='h']])
  end

  it 'parses math environment' do
    assert_data(
      "a\n$\nb\n$\nc\\(\nd\n\\)e",
      ['<mi>b</mi>', '<mi>d</mi>'],
      ["$\nb\n$", "\\(\nd\n\\)"],
      [], [], [], [],
      "a\n\001m0\001\nc\001m1\001e",
      "a\n<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>\nc<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>d</mi></math>e"
    )

    assert_data(
      '$\\$$',
      ["<mo stretchy='false'>$</mo>"],
      ['$\$$'], [], [], [], [], "\001m0\001",
      "<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mo stretchy='false'>$</mo></math>"
    )
  end

  it 'parses dmath environment' do
    assert_data(
      "a\n$$\nb\n$$\nc\\[\nd\n\\]e",
      [], [],
      ['<mi>b</mi>', '<mi>d</mi>'],
      ["$$\nb\n$$", "\\[\nd\n\\]"],
      [], [],
      "a\n\001d0\001\nc\001d1\001e",
      "a\n<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>\nc<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>d</mi></math>e"
    )
  end

  it 'parses math and dmath environment' do
    assert_data(
      'a$b$c$$d$$e\(f\)g\[h\]i',
      ['<mi>b</mi>', '<mi>f</mi>'],
      ['$b$', '\(f\)'],
      ['<mi>d</mi>', '<mi>h</mi>'],
      ['$$d$$', '\[h\]'],
      [], [],
      "a\001m0\001c\001d0\001e\001m1\001g\001d1\001i",
      "a<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>c<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>d</mi></math>e<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>f</mi></math>g<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>h</mi></math>i"
    )
  end

  it 'parses escaping' do
    assert_data('a\bc\d\e', [], [], [], [], %w[b d e], ['\b', '\d', '\e'], "a\001e0\001c\001e1\001\001e2\001", 'abcde')
    assert_data(
      '\$a$$b$$', [], [], ['<mi>b</mi>'], ['$$b$$'], [%($)], ['\$'], "\001e0\001a\001d0\001",
      "$a<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>"
    )

    assert_data("\\<\\\n", [], [], [], [], ['&lt;', "<br />\n"], ['\\<', "\\\n"], "\001e0\001\001e1\001", "&lt;<br />\n")
  end

  it 'accepts through_list option' do
    s = MathML::Util::SimpleLaTeX.new(through_list: [/\{\{.*\}\}/, /\(.*\)/])
    assert_data('{{$a$}}($b$)', [], [], [], [], [], [], '{{$a$}}($b$)', '{{$a$}}($b$)', s)

    s = MathML::Util::SimpleLaTeX.new(through_list: /\{.*\}/)
    assert_data('{$a$}', [], [], [], [], [], [], '{$a$}', '{$a$}', s)
  end

  it 'accepts parser option' do
    ps = MathML::LaTeX::Parser.new
    ps.macro.parse('\newcommand{\test}{t}')
    s = MathML::Util::SimpleLaTeX.new(parser: ps)
    assert_data(
      '$\test$', ['<mi>t</mi>'], ['$\test$'], [], [], [], [], "\001m0\001",
      "<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>t</mi></math>", s
    )
  end

  it 'accepts escape option' do
    s = MathML::Util::SimpleLaTeX.new(escape_list: [%r{/(.)}, /(\^.)/])
    assert_data(
      '\$a$', ['<mi>a</mi>'], ['$a$'], [], [], [], [], "\\\001m0\001",
      "\\<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>a</mi></math>", s
    )
    assert_data(%(/$a/$), [], [], [], [], [%($), %($)], [%(/$), %(/$)], "\001e0\001a\001e1\001", '$a$', s)
    assert_data('^\(a^\)', [], [], [], [], ['^\\', '^\\'], ['^\\', '^\\'], "\001e0\001(a\001e1\001)", '^\(a^\)', s)

    s = MathML::Util::SimpleLaTeX.new(escape_list: /_(.)/)
    assert_data('_$a$', [], [], [], [], ['$'], ['_$'], %(\001e0\001a$), '$a$', s)
  end

  it 'accepts delimiter option' do
    s = MathML::Util::SimpleLaTeX.new(delimiter: "\002\003")
    assert_data(
      'a$b$c', ['<mi>b</mi>'], ['$b$'], [], [], [], [], "a\002\003m0\002\003c",
      "a<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>c", s
    )

    s = MathML::Util::SimpleLaTeX.new(delimiter: %($))
    assert_data(
      'a$b$c', ['<mi>b</mi>'], ['$b$'], [], [], [], [], 'a$m0$c',
      "a<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>c", s
    )
  end

  it 'accepts (d)math_env_list option' do
    s = MathML::Util::SimpleLaTeX.new(math_env_list: /%(.*?)%/, dmath_env_list: /\[(.*?)\]/)
    assert_data(
      'a$b$c%d%e[f]', ['<mi>d</mi>'], ['%d%'], ['<mi>f</mi>'], ['[f]'], [], [],
      "a$b$c\001m0\001e\001d0\001",
      "a$b$c<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>d</mi></math>e<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>f</mi></math>", s
    )

    s = MathML::Util::SimpleLaTeX.new(math_env_list: [/!(.*?)!/, /"(.*)"/], dmath_env_list: [/\#(.*)\#/, /&(.*)&/])
    assert_data(
      'a!b!c"d"e#f#g&h&i',
      ['<mi>b</mi>', '<mi>d</mi>'], ['!b!', '"d"'],
      ['<mi>f</mi>', '<mi>h</mi>'], ['#f#', '&h&'],
      [], [],
      "a\001m0\001c\001m1\001e\001d0\001g\001d1\001i",
      "a<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>c<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>d</mi></math>e<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>f</mi></math>g<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>h</mi></math>i", s
    )
  end

  it 'accepts throu_list option' do
    s = MathML::Util::SimpleLaTeX.new(through_list: [/<%=.*?%>/m, /\(\(.*?\)\)/m])
    assert_data('<%=$a$%>(($b$))', [], [], [], [], [], [], '<%=$a$%>(($b$))', '<%=$a$%>(($b$))', s)

    s = MathML::Util::SimpleLaTeX.new(through_list: /<%=.*?%>/)
    assert_data('<%=$a$%>', [], [], [], [], [], [], '<%=$a$%>', '<%=$a$%>', s)
  end

  it 'accepts through_list=>[]' do
    s = MathML::Util::SimpleLaTeX.new(through_list: [])
    assert_data(
      '$a$', ['<mi>a</mi>'], [%($a$)], [], [], [], [], "\001m0\001",
      "<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>a</mi></math>", s
    )
  end

  it 'accepts without_parse option' do
    s = MathML::Util::SimpleLaTeX.new(without_parse: true)
    encoded, data = s.encode('$a$ $$b$$')
    expect(data.math_list).to eq([])
    expect(data.msrc_list).to eq(['$a$'])
    expect(data.dmath_list).to eq([])
    expect(data.dsrc_list).to eq(['$$b$$'])
    expect(encoded).to eq("\001m0\001 \001d0\001")

    s.parse(data)
    expect(data.math_list[0].attributes[:display]).to eq('inline')
    expect(data.dmath_list[0].attributes[:display]).to eq('block')
    expect(sma(data.math_list)).to eq(['<mi>a</mi>'])
    expect(sma(data.dmath_list)).to eq(['<mi>b</mi>'])
    expect(simplify_math(s.decode(encoded, data))).to eq(simplify_math("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>a</mi></math> <math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>"))
  end

  it '#set_encode_proc' do
    s = MathML::Util::SimpleLaTeX.new
    s.set_encode_proc(/\{\{/) do |scanner|
      "<%=#{scanner[1]}%>" if scanner.scan(/\{\{(.*?)\}\}/m)
    end
    src = '{{$a$}}{{$$b$$}}{{'
    assert_data(src, [], [], [], [], [], [], "\001u0\001\001u1\001{{", '<%=$a$%><%=$$b$$%>{{', s)
    encoded, data = s.encode(src)
    expect(data.user_list).to eq(['<%=$a$%>', '<%=$$b$$%>'])
    expect(data.usrc_list).to eq(['{{$a$}}', '{{$$b$$}}'])

    s.set_encode_proc(/\{\{/) do |scanner|
    end
    src = '{{a'
    assert_data(src, [], [], [], [], [], [], '{{a', '{{a', s)
    encoded, data = s.encode(src)
    expect(data.user_list).to eq([])
    expect(data.usrc_list).to eq([])
  end

  it '#set_encode_proc with arrayed regexp' do
    s = MathML::Util::SimpleLaTeX.new
    src = '{{a}}((b)){{(('
    encoded, data = s.encode(src, /\{\{/, /\(\(/) do |scanner|
      if scanner.scan(/\{\{.*?\}\}/)
        'brace'
      elsif scanner.scan(/\(\(.*?\)\)/)
        'parenthesis'
      end
    end
    expect(encoded).to eq("\001u0\001\001u1\001{{((")
    expect(s.decode(encoded, data)).to eq('braceparenthesis{{((')

    s.set_encode_proc(/\{\{/, /\(\(/) do |scanner|
      if scanner.scan(/\{\{.*?\}\}/)
        'brace'
      elsif scanner.scan(/\(\(.*?\)\)/)
        'parenthesis'
      end
    end
    encoded, data = s.encode(src)
    expect(encoded).to eq("\001u0\001\001u1\001{{((")
    expect(s.decode(encoded, data)).to eq('braceparenthesis{{((')
  end

  it '#encode accept block' do
    s = MathML::Util::SimpleLaTeX.new
    src = '{{$a$}}{{$$b$$}}{{'
    encoded, data = s.encode(src, /\{\{/) do |scanner|
      "<%=#{scanner[1]}%>" if scanner.scan(/\{\{(.*?)\}\}/m)
    end
    expect(data.math_list).to eq([])
    expect(data.dmath_list).to eq([])
    expect(data.escape_list).to eq([])
    expect(encoded).to eq("\001u0\001\001u1\001{{")
    expect(s.decode(encoded, data)).to eq('<%=$a$%><%=$$b$$%>{{')
  end

  it '#encode should accept block with #set_encode_proc' do
    s = MathML::Util::SimpleLaTeX.new
    src = '{{$a$}}{{$$b$$}}{{'
    s.set_encode_proc(/\{\{/) do |scanner|
      "<%=#{scanner[1]}%>" if scanner.scan(/\{\{(.*?)\}\}/m)
    end
    encoded, data = s.encode(src, /\{\{/) do |scanner|
      "<$=#{scanner[1]}$>" if scanner.scan(/\{\{(.*?)\}\}/m)
    end
    expect(data.math_list).to eq([])
    expect(data.dmath_list).to eq([])
    expect(data.escape_list).to eq([])
    expect(encoded).to eq("\001u0\001\001u1\001{{")
    expect(s.decode(encoded, data)).to eq('<$=$a$$><$=$$b$$$>{{')
  end

  it '#unencode' do
    src = "$\na\n$\n$$\nb\n$$"
    s = MathML::Util::SimpleLaTeX.new
    encoded, data = s.encode(src)
    expect(s.unencode(encoded, data)).to eq("$<br />\na<br />\n$\n$$<br />\nb<br />\n$$")

    s = MathML::Util::SimpleLaTeX.new(delimiter: %($))
    e, d = s.encode('$a$')
    expect(s.unencode(e, d)).to eq('$a$')
  end

  it '#set_rescue_proc' do
    src = '$a\test$ $$b\dummy$$'
    s = MathML::Util::SimpleLaTeX.new
    encoded, data = s.encode(src)
    expect(data.math_list[0]).to eq("<br />\nUndefined command.<br />\n<code>a<strong>\\test</strong></code><br />")
    expect(data.dmath_list[0]).to eq("<br />\nUndefined command.<br />\n<code>b<strong>\\dummy</strong></code><br />")

    s.set_rescue_proc do |e|
      e
    end
    encoded, data = s.encode(src)
    expect(data.math_list[0]).to be_kind_of(MathML::LaTeX::ParseError)
    expect(data.math_list[0].done).to eq('a')
    expect(data.dmath_list[0]).to be_kind_of(MathML::LaTeX::ParseError)
    expect(data.dmath_list[0].done).to eq('b')
  end

  it '#decode with block' do
    s = MathML::Util::SimpleLaTeX.new
    encoded, data = s.encode('$a$$b$$$c$$$$d$$\e\\\\')
    r = s.decode(encoded, data) do |item, opt|
      case opt[:type]
      when :dmath
        expect(item.attributes[:display]).to eq('block')
        i = strip_math(item.to_s)
      when :math
        expect(item.attributes[:display]).to eq('inline')
        i = strip_math(item.to_s)
      else
        i = item
      end
      r = "t#{opt[:type]}i#{opt[:index]}s#{opt[:src]}#{i}"
    end
    expect(r).to eq('tmathi0s$a$<mi>a</mi>tmathi1s$b$<mi>b</mi>tdmathi0s$$c$$<mi>c</mi>tdmathi1s$$d$$<mi>d</mi>tescapei0s\\eetescapei1s\\\\\\')

    r = s.decode(encoded, data) do |_item, _opt|
      nil
    end
    expect(r).to eq(s.decode(encoded, data))

    s.set_encode_proc(/\{\{/) do |scanner|
      "<%=#{scanner[1]}%>" if scanner.scan(/\{\{(.*?)\}\}/m)
    end
    encoded, data = s.encode('{{a}}{{')
    r = s.decode(encoded, data) do |item, opt|
      expect(item).to eq('<%=a%>')
      expect(opt[:type]).to eq(:user)
      expect(opt[:index]).to eq(0)
      expect(opt[:src]).to eq('{{a}}')
      nil
    end
    expect(r).to eq('<%=a%>{{')

    s.set_decode_proc do |_item, _opt|
      'dummy'
    end
    expect(s.decode(encoded, data)).to eq('dummy{{')
    r = s.decode(encoded, data) do |_item, _opt|
      nil
    end
    expect(r).to eq('<%=a%>{{')
  end

  it '#set_decode_proc' do
    s = MathML::Util::SimpleLaTeX.new
    src = '$a$$b$$$c$$$$d$$\e\\\\'
    encoded, data = s.encode(src)
    original_decoded = s.decode(encoded, data)
    s.set_decode_proc do |item, opt|
      case opt[:type]
      when :dmath
        expect(item.attributes[:display]).to eq('block')
        i = strip_math(item.to_s)
      when :math
        expect(item.attributes[:display]).to eq('inline')
        i = strip_math(item.to_s)
      else
        i = item
      end
      r = "t#{opt[:type]}i#{opt[:index]}s#{opt[:src]}#{i}"
    end
    encoded, data = s.encode(src)
    r = s.decode(encoded, data)
    expect(r).to eq('tmathi0s$a$<mi>a</mi>tmathi1s$b$<mi>b</mi>tdmathi0s$$c$$<mi>c</mi>tdmathi1s$$d$$<mi>d</mi>tescapei0s\\eetescapei1s\\\\\\')

    s.reset_decode_proc
    expect(s.decode(encoded, data)).to eq(original_decoded)
  end

  it '#unencode with block' do
    s = MathML::Util::SimpleLaTeX.new
    src = '$a$$b$$$c$$$$d$$\e\\\\'
    encoded, data = s.encode(src)
    r = s.unencode(encoded, data) do |item, opt|
      r = "t#{opt[:type]}i#{opt[:index]}#{item}"
    end
    expect(r).to eq('tmathi0$a$tmathi1$b$tdmathi0$$c$$tdmathi1$$d$$tescapei0\\etescapei1\\\\')

    r = s.unencode(encoded, data) do |_item, _opt|
      nil
    end
    expect(r).to eq(s.unencode(encoded, data))

    s.set_encode_proc(/\{\{/) do |scanner|
      "<%=#{scanner[1]}%>" if scanner.scan(/\{\{(.*?)\}\}/m)
    end
    encoded, data = s.encode('{{a}}{{')
    r = s.unencode(encoded, data) do |item, opt|
      expect(item).to eq('{{a}}')
      expect(opt[:type]).to eq(:user)
      expect(opt[:index]).to eq(0)
      nil
    end
    expect(r).to eq('{{a}}{{')
  end

  it '#set_unencode_proc' do
    s = MathML::Util::SimpleLaTeX.new
    src = '$a$$b$$$c$$$$d$$\e\\\\'
    encoded, data = s.encode(src)
    original_unencoded = s.unencode(encoded, data)

    s.set_unencode_proc do |item, opt|
      r = "t#{opt[:type]}i#{opt[:index]}#{item}"
    end
    r = s.unencode(encoded, data)
    expect(r).to eq('tmathi0$a$tmathi1$b$tdmathi0$$c$$tdmathi1$$d$$tescapei0\\etescapei1\\\\')

    s.set_unencode_proc do |_item, _opt|
      nil
    end
    expect(s.unencode(encoded, data)).to eq(original_unencoded)

    s.set_encode_proc(/\{\{/) do |scanner|
      "<%=#{scanner[1]}%>" if scanner.scan(/\{\{(.*?)\}\}/m)
    end
    encoded, data = s.encode('{{a}}{{')
    s.set_unencode_proc do |item, opt|
      expect(item).to eq('{{a}}')
      expect(opt[:type]).to eq(:user)
      expect(opt[:index]).to eq(0)
      nil
    end
    r = s.unencode(encoded, data)
    expect(r).to eq('{{a}}{{')
  end

  it '#reset_unencode_proc' do
    s = MathML::Util::SimpleLaTeX.new
    s.set_unencode_proc do |_item, _opt|
      'dummy'
    end
    encoded, data = s.encode('$a$ $$b$$')
    expect(s.unencode(encoded, data)).to eq('dummy dummy')

    s.reset_unencode_proc
    expect(s.unencode(encoded, data)).to eq('$a$ $$b$$')
  end

  it '#unencode without escaping' do
    s = MathML::Util::SimpleLaTeX.new
    src = %($<>&'"\n$ $$<>&"'\n$$)
    encoded, data = s.encode(src)
    expect(s.unencode(encoded, data)).to eq("$&lt;&gt;&amp;&apos;&quot;<br />\n$ $$&lt;&gt;&amp;&quot;&apos;<br />\n$$")
    expect(s.unencode(encoded, data, true)).to eq(src)
  end

  it '#decode without parsed' do
    s = MathML::Util::SimpleLaTeX.new
    src = '$a$$$b$$\a'
    encoded, data = s.encode(src)
    expect(s.decode(encoded, data, true)).to eq('$a$$$b$$a')
    s.decode(encoded, data, true) do |item, opt|
      case opt[:type]
      when :math
        expect(item).to eq('$a$')
      when :dmath
        expect(item).to eq('$$b$$')
      when :escape
        expect(item).to eq('a')
      end
    end

    encoded, data = s.encode("$<\n$ $$<\n$$")
    expect(s.decode(encoded, data, true)).to eq("$&lt;<br />\n$ $$&lt;<br />\n$$")
  end

  it '#decode_partial' do
    s = MathML::Util::SimpleLaTeX.new
    encoded, data = s.encode('$a$$b$')
    expect(simplify_math(s.decode_partial(:math, encoded, data))).to eq(simplify_math("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>a</mi></math><math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>"))

    s.set_encode_proc(/\\</) do |scanner|
      scanner[2] if scanner.scan(/\\<(.)(.*?)\1>/)
    end
    src = '$a$$$b$$\c\<.$d$.>'
    encoded, data = s.encode(src)
    expect(simplify_math(s.decode_partial(:math, encoded, data))).to eq(simplify_math("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>a</mi></math>\001d0\001\001e0\001\001u0\001"))
    expect(simplify_math(s.decode_partial(:dmath, encoded, data))).to eq(simplify_math("\001m0\001<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>\001e0\001\001u0\001"))
    expect(simplify_math(s.decode_partial(:escape, encoded, data))).to eq(simplify_math("\001m0\001\001d0\001c\001u0\001"))
    expect(simplify_math(s.decode_partial(:user, encoded, data))).to eq(simplify_math("\001m0\001\001d0\001\001e0\001$d$"))

    r = s.decode_partial(:math, encoded, data) do |item, opt|
      expect(opt[:type]).to eq(:math)
      expect(opt[:src]).to eq('$a$')
      expect(simplify_math(item.to_s)).to eq(simplify_math("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>a</mi></math>"))
      item
    end
    expect(simplify_math(r)).to eq(simplify_math("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>a</mi></math>\001d0\001\001e0\001\001u0\001"))

    r = s.decode_partial(:dmath, encoded, data) do |item, opt|
      expect(opt[:type]).to eq(:dmath)
      expect(opt[:src]).to eq('$$b$$')
      expect(simplify_math(item.to_s)).to eq(simplify_math("<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>"))
      item
    end
    expect(simplify_math(r)).to eq(simplify_math("\001m0\001<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>\001e0\001\001u0\001"))

    r = s.decode_partial(:escape, encoded, data) do |item, opt|
      expect(opt[:type]).to eq(:escape)
      expect(opt[:src]).to eq('\\c')
      expect(item).to eq('c')
      item
    end
    expect(r).to eq("\001m0\001\001d0\001c\001u0\001")

    r = s.decode_partial(:user, encoded, data) do |item, opt|
      expect(opt[:type]).to eq(:user)
      expect(opt[:src]).to eq('\\<.$d$.>')
      expect(item).to eq('$d$')
      item
    end
    expect(r).to eq("\001m0\001\001d0\001\001e0\001$d$")

    s = MathML::Util::SimpleLaTeX.new
    encoded, data = s.encode('\\a')
    expect(s.decode_partial(:escape, encoded, data)).to eq('a')
    r = s.decode_partial(:escape, encoded, data) do |item, opt|
    end
    expect(r).to eq("\001e0\001")

    s = MathML::Util::SimpleLaTeX.new(delimiter: %($))
    encoded, data = s.encode('$a$')
    expect(s.decode_partial(:math, encoded, data)).to match(%r{^<math.*</math>}m)
  end

  it 'keeps regexp order' do
    s = MathML::Util::SimpleLaTeX.new
    s.set_encode_proc(/\$/) do |sc|
      sc[1] + 'is rest' if sc.scan(/\$(.*)\z/)
    end

    encoded, data = s.encode('$a$$b')
    expect(encoded).to eq("\001m0\001\001u0\001")
  end

  it 'parse eqnarray' do
    s = MathML::Util::SimpleLaTeX.new
    src = <<~'EOT'
      test
      \begin
      {eqnarray}
      a&=&b\\
      c&=&d
      \end
      {eqnarray}
      end
    EOT
    encoded, data = s.encode(src, MathML::Util::EQNARRAY_RE) do |scanner|
      s.parse_eqnarray(scanner[1]) if scanner.scan(MathML::Util::EQNARRAY_RE)
    end
    expect(encoded).to eq("test\n\001u0\001\nend\n")
    expect(simplify_math(s.decode(encoded, data))).to eq(simplify_math("test\n<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mtable><mtr><mtd><mi>a</mi></mtd><mtd><mo stretchy='false'>=</mo></mtd><mtd><mi>b</mi></mtd></mtr><mtr><mtd><mi>c</mi></mtd><mtd><mo stretchy='false'>=</mo></mtd><mtd><mi>d</mi></mtd></mtr></mtable></math>\nend\n"))

    encoded, data = s.encode('\begin{eqnarray}a\end{eqnarray}', MathML::Util::EQNARRAY_RE) do |scanner|
      s.parse_eqnarray(scanner[1]) if scanner.scan(MathML::Util::EQNARRAY_RE)
    end
    expect(s.decode(encoded, data)).to eq("<br />\nNeed more column.<br />\n<code>\\begin{eqnarray}a<strong>\\end{eqnarray}</strong></code><br />")
  end

  it 'parses single command' do
    s = MathML::Util::SimpleLaTeX.new
    encoded, data = s.encode(%q(\alpha\|\<\>\&\"\'\test), MathML::Util::SINGLE_COMMAND_RE) do |scanner|
      s.parse_single_command(scanner.matched) if scanner.scan(MathML::Util::SINGLE_COMMAND_RE)
    end
    expect(encoded).to eq("\001u0\001\001e0\001\001e1\001\001e2\001\001e3\001\001e4\001\001e5\001\001u1\001")
    expect(simplify_math(s.decode(encoded, data))).to eq(simplify_math("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>&alpha;</mi></math>|&lt;&gt;&amp;&quot;&apos;test"))
    encoded, data = s.encode('\alpha test', MathML::Util::SINGLE_COMMAND_RE) do |scanner|
      s.parse_single_command(scanner.matched) if scanner.scan(MathML::Util::SINGLE_COMMAND_RE)
    end
    expect(encoded).to eq("\001u0\001test")
    expect(simplify_math(s.decode(encoded, data))).to eq(simplify_math("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>&alpha;</mi></math>test"))

    encoded, data = s.encode('\alpha  test', MathML::Util::SINGLE_COMMAND_RE) do |scanner|
      s.parse_single_command(scanner.matched) if scanner.scan(MathML::Util::SINGLE_COMMAND_RE)
    end
    expect(encoded).to eq("\001u0\001 test")
    expect(simplify_math(s.decode(encoded, data))).to eq(simplify_math("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>&alpha;</mi></math> test"))

    encoded, data = s.encode("\\alpha\ntest", MathML::Util::SINGLE_COMMAND_RE) do |scanner|
      s.parse_single_command(scanner.matched) if scanner.scan(MathML::Util::SINGLE_COMMAND_RE)
    end
    expect(encoded).to eq("\001u0\001\ntest")
  end

  it '#encode can be called twice or more times' do
    s = MathML::Util::SimpleLaTeX.new
    encoded, data = s.encode('$a$')
    encoded, data = s.encode('$b$', data)
    expect(encoded).to eq("\001m1\001")
    expect(data.msrc_list).to eq(['$a$', '$b$'])
    expect(data.math_list.size).to eq(2)
    expect(strip_math(data.math_list[0].to_s)).to eq('<mi>a</mi>')
    expect(strip_math(data.math_list[1].to_s)).to eq('<mi>b</mi>')

    encoded, data = s.encode('a', data, /a/) do |sc|
      sc.scan(/a/)
    end
    expect(encoded).to eq("\001u0\001")
    expect(data.msrc_list).to eq(['$a$', '$b$'])
    expect(data.usrc_list).to eq(['a'])

    encoded, data = s.encode('a', nil, /a/) do |s|
      s.scan(/a/)
    end
    expect(encoded).to eq("\001u0\001")
    expect(data.usrc_list).to eq(['a'])
  end
end
