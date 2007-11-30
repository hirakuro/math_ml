# Test for math_ml.rb
#
# Copyright (C) 2005, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.

require "test/unit"
require "math_ml"
require "math_ml_test_util"

class TC_Mathml_rb < Test::Unit::TestCase
	def test_double_require
		assert(require("lib/math_ml"))
		assert_nothing_raised do
			MathML::LaTeX::Parser.new
		end
	end
end

class TC_MathML_Element < Test::Unit::TestCase
	include Util4TC_MathML
	include MathML

	def test_display_style
		e = Element.new("test")
		assert(!e.display_style)

		e = Element.new("test").as_display_style
		assert_equal(MathML::Element, e.class)
		assert(e.display_style)
	end

	def test_pop
		e = Element.new("super")
		assert_equal(nil, e.pop)

		s = Element.new("sub")
		e << s
		assert_equal(s, e.pop)
		assert_equal(nil, e.pop)

		e << "text"
		assert_equal(MathML.pcstring("text"), e.pop)
		assert_equal(nil, e.pop)
	end

	def test_pcstring
		assert_equal("&lt;&gt;&amp;&quot;&apos;", MathML.pcstring('<>&"\'').to_s)
		assert_equal('<tag>&amp;"\'</tag>', MathML.pcstring('<tag>&amp;"\'</tag>', true).to_s)
	end
end

class TC_MathML_LaTeX_Scanner < Test::Unit::TestCase
	include MathML::LaTeX

	def test_done
		s = Scanner.new("0123")
		s.pos = 2
		assert_equal("01", s.done)
		assert_equal("23", s.rest)
	end

	def test__scan
		s = Scanner.new(" ")
		assert_equal(" ", s._scan(/\s/))
		assert_equal(1, s.pos)
	end

	def test__check
		s = Scanner.new(" ")
		assert_equal(" ", s._check(/\s/))
		assert_equal(0, s.pos)
	end

	def test_scan
		s = Scanner.new(" a")
		assert_equal("a", s.scan(/a/))
		assert_equal(2, s.pos)

		s.reset
		assert_equal(nil, s.scan(/b/))
		assert_equal(0, s.pos)

		s = Scanner.new(" %comment\na")
		assert_equal("a", s.scan(/a/))
		assert_equal(11, s.pos)

		s.reset
		assert_equal(nil, s.scan(/b/))
		assert_equal(0, s.pos)
	end

	def test_check
		s = Scanner.new(" a")
		assert_equal("a", s.check(/a/))
		assert_equal(0, s.pos)

		s.reset
		assert_equal(nil, s.check(/b/))
		assert_equal(0, s.pos)
	end

	def test_eos
		assert(Scanner.new("").eos?)
		assert(Scanner.new(" ").eos?)
		assert(Scanner.new(" %test\n%test").eos?)
		assert(!Scanner.new(" a").eos?)
		assert(!Scanner.new(" \\command").eos?)
	end


	def test_check_command
		assert_equal(nil, Scanner.new("test").check_command)
		s = Scanner.new(' \test')
		assert_equal('\test', s.check_command)
		assert_equal("test", s[1])
		assert_equal('\test', Scanner.new(' \test next').check_command)
		assert_equal('\test', Scanner.new(' \test_a').check_command)
	end

	def test_scan_command
		assert_equal(nil, Scanner.new("test").scan_command)

		s = Scanner.new(' \test')
		assert_equal('\test', s.scan_command)
		assert_equal("test", s[1])
		assert_equal(6, s.pos)

		s = Scanner.new(' \test rest')
		assert_equal('\test', s.scan_command)
		assert_equal(6, s.pos)

		s = Scanner.new(' \test_a')
		assert_equal('\test', s.scan_command)
		assert_equal(6, s.pos)

		s = Scanner.new(' \_test')
		assert_equal('\_', s.check_command)
		assert_equal('\_', s.scan_command)
		assert_equal("test", s.rest)

	end

	def test_scan_block
		assert_equal(nil, Scanner.new(" a").scan_block)
		assert_equal(nil, Scanner.new(" a").check_block)

		i = " {{}{}{{}{}}} "
		e = "{#{i}}"
		s = Scanner.new(" #{e} test")
		assert_equal(e, s.check_block)
		assert_equal(e, s.matched)
		assert_equal(i, s[1])
		assert_equal(e, s.scan_block)
		assert_equal(e, s.matched)
		assert_equal(i, s[1])
		assert_equal(" test", s.rest)

		assert_equal(nil, Scanner.new(' \command test').scan_block)
		assert_equal(nil, Scanner.new(' \command test').check_block)

		assert_equal(nil, Scanner.new("").scan_block)
		assert_equal(nil, Scanner.new("").check_block)

		assert_equal(nil, Scanner.new(" ").scan_block)
		assert_equal(nil, Scanner.new(" ").check_block)

		s = Scanner.new("{test")
		e = assert_raises(BlockNotClosed){s.scan_block}
	end

	def test_scan_any
		s0 = " %comment\n "
		s1 = "{}"
		s = Scanner.new(s0+s1)
		assert_equal(s1, s.scan_any)
		s.reset
		assert_equal(s0+s1, s.scan_any(true))
		assert_equal(s1, s.matched)

		s1 = '\command'
		s = Scanner.new(s0+s1)
		assert_equal(s1, s.scan_any)
		s.reset
		assert_equal(s0+s1, s.scan_any(true))

		s1 = 'a'
		s = Scanner.new(s0+s1)
		assert_equal(s1, s.scan_any)
		s.reset
		assert_equal(s0+s1, s.scan_any(true))

		s = Scanner.new(" ")
		assert_equal(nil, s.scan_any)
		s.reset
		assert_equal(" ", s.scan_any(true))

		s = Scanner.new('\begin{env}test\end{env}')
		assert_equal('\begin', s.scan_any)
	end

	def test_peek_command
		assert_equal("test", Scanner.new(' \test').peek_command)
		assert_equal(nil, Scanner.new("").peek_command)
		assert_equal(nil, Scanner.new(" ").peek_command)
		assert_equal(nil, Scanner.new(" a").peek_command)
	end

	def test_scan_option
		s = Scanner.new(" []")
		assert_equal("[]", s.scan_option)
		assert_equal("", s[1])
		assert_equal(3, s.pos)

		s = Scanner.new(" [ opt ]")
		assert_equal("[ opt ]", s.scan_option)
		assert_equal(" opt ", s[1])
		assert_equal(8, s.pos)

		s = Scanner.new(" [[]]")
		assert_equal("[[]", s.scan_option)
		assert_equal("[", s[1])

		s = Scanner.new(" [{[]}]")
		assert_equal("[{[]}]", s.scan_option)
		assert_equal("{[]}", s[1])

		assert_raises(OptionNotClosed){Scanner.new("[").scan_option}
	end

	def test_check_option
		s = Scanner.new(" []")
		assert_equal("[]", s.check_option)
		assert_equal("", s[1])
		assert_equal(0, s.pos)

		s = Scanner.new(" [ opt ]")
		assert_equal("[ opt ]", s.check_option)
		assert_equal(" opt ", s[1])
		assert_equal(0, s.pos)

		s = Scanner.new(" [[]]")
		assert_equal("[[]", s.check_option)
		assert_equal("[", s[1])

		s = Scanner.new(" [{[]}]")
		assert_equal("[{[]}]", s.check_option)
		assert_equal("{[]}", s[1])

		assert_raises(OptionNotClosed){Scanner.new("[").check_option}
	end
end

class TC_MathML_LaTeX_Macro < Test::Unit::TestCase
	include Util4TC_MathML
	include MathML::LaTeX

	def setup
		@src = <<'EOS'
\newcommand{\newcom}{test}
\newcommand{\paramcom}[2]{param2 #2, param1 #1.}
\newcommand\ALPHA\alpha
\newcommand\BETA[1]\beta
\newcommand{\nothing}{}
\newenvironment{newenv}{begin_newenv}{end_newenv}
\newenvironment{paramenv}[2]{begin 1:#1, 2:#2}{end 2:#2 1:#1}
\newenvironment{nothing}{}{}
\newenvironment{separated environment}{sep}{env}
\newenvironment ENV
EOS
		super
	end

	def test_parse
		m = Macro.new
		assert_nothing_raised{m.parse(@src)}

		assert_parse_error("Need newcommand.", '\\newcommand{', "notcommand}{}"){m.parse('\newcommand{notcommand}{}')}
		assert_parse_error("Syntax error.", '\newcommand{\separated', " command}{}"){m.parse('\newcommand{\separated command}{}')}
		assert_parse_error("Need parameter.", '\newcommand{\nobody}', ""){m.parse('\newcommand{\nobody}')}
		assert_parse_error("Parameter \# too large.", '\newcommand{\noparam}{#', "1}"){m.parse('\newcommand{\noparam}{#1}')}
		assert_parse_error("Parameter \# too large.", '\newcommand{\overopt}[1]{#1#', "2}"){m.parse('\newcommand{\overopt}[1]{#1#2}')}
		assert_parse_error("Need positive number.", '\newcommand{\strangeopt}[', "-1]"){m.parse('\newcommand{\strangeopt}[-1]')}
		assert_parse_error("Need positive number.", '\newcommand{\strangeopt}[', "a]"){m.parse('\newcommand{\strangeopt}[a]')}

		assert_parse_error("Syntax error.", '\newenvironment{', '\command}{}{}'){m.parse('\newenvironment{\command}{}{}')}
		assert_parse_error("Need begin block.", '\newenvironment{nobegin}', ""){m.parse('\newenvironment{nobegin}')}
		assert_parse_error("Need end block.", '\newenvironment{noend}{}', ""){m.parse('\newenvironment{noend}{}')}
		assert_parse_error("Parameter \# too large.", '\newenvironment{noparam}{#', "1}{}"){m.parse('\newenvironment{noparam}{#1}{}')}
		assert_parse_error("Parameter \# too large.", '\newenvironment{overparam}[1]{#1#', "2}{}"){m.parse('\newenvironment{overparam}[1]{#1#2}{}')}
		assert_parse_error("Need positive number.", '\newenvironment{strangeparam}[', "-1]{}{}"){m.parse('\newenvironment{strangeparam}[-1]{}{}')}
		assert_parse_error("Need positive number.", '\newenvironment{strangeparam}[', "a]{}{}"){m.parse('\newenvironment{strangeparam}[a]{}{}')}

		assert_parse_error("Syntax error.", '\newcommand{\valid}{OK} ', '\invalid{\test}{NG}'){m.parse('\newcommand{\valid}{OK} \invalid{\test}{NG}')}
		assert_parse_error("Syntax error.", '\newcommand{\valid}{OK} ', 'invalid{\test}{NG}'){m.parse('\newcommand{\valid}{OK} invalid{\test}{NG}')}

		assert_parse_error("Option not closed.", '\newcommand{\newcom}', '[test'){m.parse('\newcommand{\newcom}[test')}
		assert_parse_error("Option not closed.", '\newcommand{\newcom}[1]', '[test'){m.parse('\newcommand{\newcom}[1][test')}
		assert_parse_error("Parameter \# too large.", '\newcommand{\newcom}[1][]{#1#', '2}'){m.parse('\newcommand{\newcom}[1][]{#1#2}')}
		assert_parse_error("Option not closed.", '\newenvironment{newenv}[1]', '[test'){m.parse('\newenvironment{newenv}[1][test')}
		assert_parse_error("Option not closed.", '\newenvironment{newenv}[1]', '[test'){m.parse('\newenvironment{newenv}[1][test')}

		assert_parse_error("Block not closed.", '\newcommand', '{\newcom'){m.parse('\newcommand{\newcom')}
		assert_parse_error("Block not closed.", '\newcommand{\newcom}', '{test1{test2}{test3'){m.parse('\newcommand{\newcom}{test1{test2}{test3')}

		assert_parse_error("Parameter \# too large.", '\newenvironment{newenv}[1][]{#1 #', '2}'){m.parse('\newenvironment{newenv}[1][]{#1 #2}')}
	end

	def test_commands
		m = Macro.new
		m.parse(@src)

		assert_equal(0, m.commands("newcom").num)
		assert_equal(2, m.commands("paramcom").num)
		assert_equal(nil, m.commands("no"))
	end

	def test_expand_command
		m = Macro.new
		m.parse(@src)

		assert_equal(nil, m.expand_command("not coommand", []))

		assert_equal("test", m.expand_command("newcom", []))
		assert_equal("test", m.expand_command("newcom", ["dummy_param"]))
		assert_equal("param2 2, param1 1.", m.expand_command("paramcom", ["1", "2"]))
		assert_equal("param2 34, param1 12.", m.expand_command("paramcom", ["12", "34"]))
		assert_parse_error("Need more parameter.", "", ""){m.expand_command("paramcom", ["12"])}
		assert_parse_error("Need more parameter.", "", ""){m.expand_command("paramcom", [])}
	end

	def test_environments
		m = Macro.new
		m.parse(@src)

		assert_equal(0, m.environments("newenv").num)
		assert_equal(2, m.environments("paramenv").num)
		assert_equal(nil, m.environments("not_env"))
		assert_equal(0, m.environments("separated environment").num)
	end

	def test_expand_environment
		m = Macro.new
		m.parse(@src)

		assert_equal(nil, m.expand_environment('notregistered', "dummy", []))
		assert_equal(' begin_newenv body end_newenv ', m.expand_environment("newenv", "body", []))
		assert_equal(' begin 1:1, 2:2 body end 2:2 1:1 ', m.expand_environment("paramenv", "body", ["1", "2"]))
		assert_equal(' begin 1:12, 2:34 body end 2:34 1:12 ', m.expand_environment("paramenv", "body", ["12", "34"]))
		assert_parse_error("Need more parameter.", "", ""){m.expand_environment("paramenv", "body", ["1"])}
		assert_parse_error("Need more parameter.", "", ""){m.expand_environment("paramenv", "body", [])}
		assert_equal('  body  ', m.expand_environment("nothing", "body", []))
		assert_equal(' sep body env ', m.expand_environment("separated environment", "body", []))
		assert_equal(' N body V ', m.expand_environment("E", "body", []))
	end

	def test_expand_with_options

		src = <<'EOS'
\newcommand{\opt}[1][x]{#1}
\newcommand{\optparam}[2][]{#1#2}
\newenvironment{newenv}[1][x]{s:#1}{e:#1}
\newenvironment{optenv}[2][]{s:#1}{e:#2}
EOS

		m = Macro.new
		m.parse(src)

		assert_equal('x', m.expand_command("opt", []))
		assert_equal('1', m.expand_command("opt", [], "1"))

		assert_equal('1', m.expand_command("optparam", ["1"]))
		assert_equal('21', m.expand_command("optparam", ["1"], "2"))

		assert_equal(" s:x test e:x ", m.expand_environment("newenv", "test", []))
		assert_equal(" s:1 test e:1 ", m.expand_environment("newenv", "test", [], "1"))

		assert_equal(" s: test e:1 ", m.expand_environment("optenv", "test", ["1"]))
		assert_equal(" s:2 test e:1 ", m.expand_environment("optenv", "test", ["1"], "2"))
	end
end

class TC_MathML_LaTeX_Parser < Test::Unit::TestCase
	include MathML::LaTeX
	include Util4TC_MathML

	### Sub routines ###

	def check_chr(stag, etag, str, print=false)
		str.each_byte do |b|
			assert_equal("#{stag}#{b.chr}#{etag}", smml(b.chr))
			puts smml(b.chr) if print
		end
	end

	def check_hash(stag, etag, hash, print=false)
		hash.each do |k, v|
			e = "#{stag}#{v}#{etag}"
			s = smml(k)
			assert_equal(e, s)
			puts "#{k} => #{s}" if print
		end
	end

	def check_entity(stag, etag, hash, print=false)
		h = Hash.new
		hash.each do |k, v|
			h[k] = "&#{v};"
		end
		check_hash(stag, etag, h, print)
	end

	### Tests ###

	def test_nobody
		p = Parser.new
		assert_equal("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML' />", p.parse("").to_s)
		assert_equal("<math display='block' xmlns='http://www.w3.org/1998/Math/MathML' />", p.parse("", true).to_s)
		assert_equal("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML' />", p.parse("", false).to_s)
	end

	def test_ignore_space
		assert_equal("<mrow><mi>a</mi></mrow>", smml("{ a }"))
	end

	def test_block
		assert_parse_error("Block not closed.", "test {test} ", "{test"){smml("test {test} {test")}
	end

	def test_parse_error
		src = 'a\hoge c'
		e = assert_raises(ParseError){smml(src)}
		assert_equal(["Undefined command.", "a", '\hoge c'], parse_error(e))

		src = '\sqrt\sqrt1'
		e = assert_raises(ParseError){smml(src)}
		assert_equal(["Syntax error.", '\sqrt\sqrt', "1"], parse_error(e))

		src = "a{b"
		e = assert_raises(ParseError){smml(src)}
		assert_equal(["Block not closed.", "a", "{b"], parse_error(e))
	end

	def test_numerics
		assert_equal("<mn>1234567890</mn>", smml('1234567890'))
		assert_equal("<mn>1.2</mn>", smml('1.2'))
		assert_equal("<mn>1</mn><mo>.</mo>", smml('1.'))
		assert_equal("<mn>.2</mn>", smml('.2'))
		assert_equal("<mn>1.2</mn><mn>.3</mn>", smml('1.2.3'))
	end

	def test_alphabets
		check_chr("<mi>", "</mi>", "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
	end

	def test_non_alphabet_command
		assert_equal("<mspace width='0.167em' />", smml('\,'))
		assert_equal("<mo>&DoubleVerticalBar;</mo>", smml('\|'))
	end

	def test_operators
		check_chr("<mo>", "</mo>", ",.+-*=/()[]|;:!")
		check_entity("<mo>", "</mo>", {"<"=>"lt", ">"=>"gt", '"'=>"quot", "'"=>"apos"})
		check_hash("<mo>", "</mo>", {'\backslash'=>'\\', '\%'=>'%', '\{'=>'{', '\}'=>'}', '\$'=>'$', '\#'=>'#'})
	end

	def test_sqrt
		assert_equal("<msqrt><mi>a</mi></msqrt>", smml('\sqrt a'))
		assert_equal("<mroot><mn>3</mn><mn>2</mn></mroot>", smml('\sqrt[2]3'))
		assert_equal("<mroot><mn>3</mn><mrow><mn>2</mn><mi>a</mi></mrow></mroot>", smml('\sqrt[2a]3'))
		e = assert_raises(ParseError){smml('\sqrt[12')}
		assert_equal(["Option not closed.", '\sqrt', "[12"], parse_error(e))
	end

	def test_subsup
		assert_equal("<msubsup><mi>a</mi><mi>b</mi><mi>c</mi></msubsup>", smml("a_b^c"))
		assert_equal("<msub><mi>a</mi><mi>b</mi></msub>", smml("a_b"))
		assert_equal("<msup><mi>a</mi><mi>b</mi></msup>", smml("a^b"))
		assert_equal("<msubsup><none /><mi>a</mi><mi>b</mi></msubsup>", smml("_a^b"))

		e = assert_raises(ParseError){smml("a_b_c")}
		assert_equal(["Double subscript.", "a_b", "_c"], parse_error(e))
		e = assert_raises(ParseError){smml("a^b^c")}
		assert_equal(["Double superscript.", "a^b", "^c"], parse_error(e))
		e = assert_raises(ParseError){smml("a_")}
		assert_equal(["Subscript not exist.", "a_", ""], parse_error(e))
		e = assert_raises(ParseError){smml("a^")}
		assert_equal(["Superscript not exist.", "a^", ""], parse_error(e))
	end

	def test_underover
		assert_equal("<munderover><mo>&sum;</mo><mi>a</mi><mi>b</mi></munderover>", smml('\sum_a^b', true))
		assert_equal("<msubsup><mo>&sum;</mo><mi>a</mi><mi>b</mi></msubsup>", smml('\sum_a^b'))
		assert_equal("<munder><mo>&sum;</mo><mi>a</mi></munder>", smml('\sum_a', true))
		assert_equal("<mover><mo>&sum;</mo><mi>a</mi></mover>", smml('\sum^a', true))
		assert_equal("<msub><mo>&sum;</mo><mi>a</mi></msub>", smml('\sum_a'))
		assert_equal("<msup><mo>&sum;</mo><mi>a</mi></msup>", smml('\sum^a'))
		e = assert_raises(ParseError){smml('\sum_b_c')}
		assert_equal(["Double subscript.", '\sum_b', "_c"], parse_error(e))
		e = assert_raises(ParseError){smml('\sum^b^c')}
		assert_equal(["Double superscript.", '\sum^b', "^c"], parse_error(e))
		e = assert_raises(ParseError){smml('\sum_')}
		assert_equal(["Subscript not exist.", '\sum_', ""], parse_error(e))
		e = assert_raises(ParseError){smml('\sum^')}
		assert_equal(["Superscript not exist.", '\sum^', ""], parse_error(e))
	end

	def test_fonts
		assert_equal("<mi>a</mi><mrow><mi mathvariant='bold'>b</mi><mi mathvariant='bold'>c</mi></mrow><mi>d</mi>", smml('a{\bf b c}d'))
		assert_equal("<mi mathvariant='bold'>a</mi><mrow><mi>b</mi><mi>c</mi></mrow><mi mathvariant='bold'>d</mi>", smml('\bf a{\it b c}d'))
		assert_equal("<mi>a</mi><mrow><mi mathvariant='normal'>b</mi><mi mathvariant='normal'>c</mi></mrow><mi>d</mi>", smml('a{\rm b c}d'))

		assert_equal("<mi>a</mi><mrow><mrow><mi mathvariant='bold'>b</mi><mi mathvariant='bold'>c</mi></mrow></mrow><mi>d</mi>", smml('a \mathbf{bc}d'))
		assert_equal("<mrow><mn mathvariant='bold'>1</mn></mrow><mn>2</mn>", smml('\mathbf12'))
		assert_equal("<mi mathvariant='bold'>a</mi><mrow><mrow><mi>b</mi><mi>c</mi></mrow></mrow><mi mathvariant='bold'>d</mi>", smml('\bf a \mathit{bc} d'))
		assert_equal("<mi>a</mi><mrow><mrow><mi mathvariant='normal'>b</mi><mi mathvariant='normal'>c</mi></mrow></mrow><mi>d</mi>", smml('a\mathrm{bc}d'))

		assert_equal("<mi>a</mi><mrow><mrow><mi>&bopf;</mi><mi>&copf;</mi></mrow></mrow><mi>d</mi>", smml('a \mathbb{b c} d'))
		assert_equal("<mi>a</mi><mrow><mrow><mi>&bscr;</mi><mi>&cscr;</mi></mrow></mrow><mi>d</mi>", smml('a \mathscr{b c} d'))
		assert_equal("<mi>a</mi><mrow><mrow><mi>&bfr;</mi><mi>&cfr;</mi></mrow></mrow><mi>d</mi>", smml('a \mathfrak{b c} d'))
		assert_equal("<mi>a</mi><mrow><mrow><mi mathvariant='bold-italic'>b</mi><mi mathvariant='bold-italic'>c</mi></mrow></mrow><mi>d</mi>", smml('a \bm{bc}d'))
		assert_equal("<mrow><mi mathvariant='bold-italic'>a</mi></mrow><mi>b</mi>", smml('\bm ab'))
		e = assert_raises(ParseError){smml('\mathit')}
		assert_equal(["Syntax error.", '\mathit', ""], parse_error(e))
		e = assert_raises(ParseError){smml('\mathrm')}
		assert_equal(["Syntax error.", '\mathrm', ""], parse_error(e))
		e = assert_raises(ParseError){smml('\mathbf')}
		assert_equal(["Syntax error.", '\mathbf', ""], parse_error(e))
		e = assert_raises(ParseError){smml('\mathbb')}
		assert_equal(["Syntax error.", '\mathbb', ""], parse_error(e))
		e = assert_raises(ParseError){smml('\mathscr')}
		assert_equal(["Syntax error.", '\mathscr', ""], parse_error(e))
		e = assert_raises(ParseError){smml('\mathfrak')}
		assert_equal(["Syntax error.", '\mathfrak', ""], parse_error(e))
	end

	def test_mbox
		assert_equal("<mi>a</mi><mtext>b c</mtext><mi>d</mi>", smml('a\mbox{b c}d'))
		assert_equal('<mtext>&lt;&gt;&apos;&quot;&amp;</mtext>', smml('\mbox{<>\'"&}'))
	end

	def test_frac
		assert_equal("<mfrac><mi>a</mi><mi>b</mi></mfrac>", smml('\frac ab'))
		assert_equal("<mfrac><mn>1</mn><mn>2</mn></mfrac>", smml('\frac12'))

		e = assert_raises(ParseError){smml('\frac a')}
		assert_equal(["Syntax error.", '\frac a', ""], parse_error(e))
	end

	def test_environment
		e = assert_raises(ParseError){smml('{\begin}rest')}
		assert_equal(["Environment name not exist.", '{\begin', '}rest'], parse_error(e))

		e = assert_raises(ParseError){smml('{\begin{array}{c}dummy}rest')}
		assert_equal(['Matching \end not exist.', '{\begin{array}{c}dummy', '}rest'], parse_error(e))

		e = assert_raises(ParseError){smml('\begin{array}c dummy\end{test}')}
		assert_equal(["Environment mismatched.", '\begin{array}c dummy\end', "{test}"], parse_error(e))

		e = assert_raises(ParseError){smml('\left(\begin{array}\right)')}
		assert_equal(["Syntax error.", '\left(\begin{array}', '\right)'], parse_error(e))
	end

	def test_array_env
		assert_equal("<mtable columnalign='left right center'><mtr><mtd><mi>a</mi></mtd><mtd><mi>b</mi></mtd><mtd><mi>c</mi></mtd></mtr><mtr><mtd><mi>d</mi></mtd><mtd><mi>e</mi></mtd><mtd><mi>f</mi></mtd></mtr></mtable>", smml('\begin{array}{lrc} a & b & c \\\\ d & e & f \\\\ \end{array}'))

		assert_equal("<mtable columnalign='left right center'><mtr><mtd><mi>a</mi></mtd><mtd><mi>b</mi></mtd><mtd><mi>c</mi></mtd></mtr><mtr><mtd><mi>d</mi></mtd><mtd><mi>e</mi></mtd><mtd><mi>f</mi></mtd></mtr></mtable>", smml('\begin{array}{lrc}a&b&c\\\\d&e&f \end{array}'))

		assert_equal("<mtable />", smml('\begin{array}{c}\end{array}'))

		e = assert_raises(ParseError){smml('\begin{array}\end{array}')}
		assert_equal(['Syntax error.', '\begin{array}', '\end{array}'], parse_error(e))

		e = assert_raises(ParseError){smml('\begin{array}{a}\end{array}')}
		assert_equal(["Syntax error.", '\begin{array}{', 'a}\end{array}'], parse_error(e))

		e = assert_raises(ParseError){smml('\begin{array}{cc}a\\\\b&c\end{array}')}
		assert_equal(["Need more column.", '\begin{array}{cc}a', '\\\\b&c\end{array}'], parse_error(e))

		e = assert_raises(ParseError){smml('\begin{array}{cc}a\end{array}')}
		assert_equal(["Need more column.", '\begin{array}{cc}a', '\end{array}'], parse_error(e))

		e = assert_raises(ParseError){smml('\begin{array}{c}a&\end{array}')}
		assert_equal(["Too many column.", '\begin{array}{c}a', '&\end{array}'], parse_error(e))

		assert_equal("<mtable><mtr><mtd /><mtd /></mtr></mtable>", smml('\begin{array}{cc}&\end{array}'))

		assert_equal("<mfenced close='}' open='{'><mrow><mtable><mtr><mtd><msub><mi>a</mi><mi>b</mi></msub></mtd></mtr></mtable></mrow></mfenced>", smml('\left\{\begin{array}ca_b\end{array}\right\}'))

		assert_equal("<mtable columnalign='center left center center center right center'><mtr><mtd><mrow><msub><mi>a</mi><mn>1</mn></msub></mrow></mtd><mtd><mi>A</mi></mtd><mtd><mi>b</mi></mtd><mtd><mi>B</mi></mtd><mtd><mi>c</mi></mtd><mtd><mi>C</mi></mtd><mtd><mi>d</mi></mtd></mtr></mtable>", smml('\begin{array}{@{a_1}l@bc@cr@d}A&B&C\end{array}'))

		assert_equal("<mfenced close='}' open='{'><mrow><mtable><mtr><mtd><msub><mi>a</mi><mi>b</mi></msub></mtd></mtr></mtable></mrow></mfenced>", smml('\left\{\begin{array}ca_b\end{array}\right\}'))

		assert_equal("<mtable columnlines='solid'><mtr><mtd><mi>a</mi></mtd><mtd><mi>b</mi></mtd></mtr><mtr><mtd><mi>c</mi></mtd><mtd><mi>d</mi></mtd></mtr></mtable>", smml('\begin{array}{c|c}a&b\\\\c&d\end{array}'))
		assert_equal("<mtable columnlines='solid solid'><mtr><mtd /><mtd><mi>a</mi></mtd><mtd /></mtr><mtr><mtd /><mtd><mi>c</mi></mtd><mtd /></mtr></mtable>", smml('\begin{array}{|c|}a\\\\c\end{array}'))
		assert_equal("<mtable rowlines='solid'><mtr /><mtr><mtd><mi>c</mi></mtd></mtr></mtable>", smml('\begin{array}{c}\hline c\end{array}'))
		assert_equal("<mtable rowlines='solid'><mtr><mtd><mi>c</mi></mtd><mtd><mi>a</mi></mtd><mtd><mi>c</mi></mtd><mtd><mi>c</mi></mtd></mtr><mtr><mtd /><mtd /><mtd /><mtd /></mtr></mtable>", smml('\begin{array}{c@acc}c&c&c\\\\\hline\end{array}'))
		assert_equal("<mtable rowlines='solid none solid'><mtr /><mtr><mtd><mi>a</mi></mtd></mtr><mtr><mtd><mi>b</mi></mtd></mtr><mtr><mtd /></mtr></mtable>", smml('\begin{array}{c}\hline a\\\\b\\\\\hline\end{array}'))
	end

	def test_leftright
		assert_equal("<mfenced close=')' open='('><mrow><mfrac><mn>1</mn><mn>2</mn></mfrac></mrow></mfenced>", smml('\left(\frac12\right)'))

		assert_equal("<mfenced close='&rfloor;' open='&lfloor;'><mrow><mi>a</mi></mrow></mfenced>", smml('\left \lfloor a\right \rfloor'))

		assert_equal("<mfenced close='}' open='{'><mrow><mi>a</mi></mrow></mfenced>", smml('\left \{ a \right \}'))

		assert_equal("<mfenced close='}' open='{'><mrow><mtable><mtr><mtd><mtable><mtr><mtd><mi>a</mi></mtd></mtr></mtable></mtd></mtr></mtable></mrow></mfenced>", smml('\left\{\begin{array}c\begin{array}ca\end{array}\end{array}\right\}'))

		assert_equal("<mfenced close=')' open='('><mrow><msub><mo>&sum;</mo><mi>a</mi></msub></mrow></mfenced>", smml('\left(\sum_a\right)'))
		assert_equal("<mfenced close=')' open='('><mrow><munder><mo>&sum;</mo><mi>a</mi></munder></mrow></mfenced>", smml('\left(\sum_a\right)', true))

		e = assert_raises(ParseError){smml('\left(test')}
		assert_equal(["Brace not closed.", '\left', '(test'], parse_error(e))

		assert_equal("<mfenced close='&DoubleVerticalBar;' open='&DoubleVerticalBar;'><mrow><mi>a</mi></mrow></mfenced>", smml('\left\|a\right\|'))

		e = assert_raises(ParseError){smml('\left')}
		assert_equal(["Need brace here.", '\left', ""], parse_error(e))
	end

	def test_over
		assert_equal("<mover><mi>a</mi><mo>&circ;</mo></mover>", smml('\hat a'))
		assert_equal("<mover><mn>1</mn><mo>&circ;</mo></mover><mn>2</mn>", smml('\hat12'))
		e = assert_raises(ParseError){smml('{\hat}a')}
		assert_equal(["Syntax error.", '{\hat', '}a'], parse_error(e))
	end

	def test_under
		assert_equal("<munder><mi>a</mi><mo>&macr;</mo></munder>", smml('\underline a'))
		assert_equal("<munder><mn>1</mn><mo>&macr;</mo></munder><mn>2</mn>", smml('\underline12'))
		e = assert_raises(ParseError){smml('{\underline}a')}
		assert_equal(["Syntax error.", '{\underline', '}a'], parse_error(e))
	end

	def test_stackrel
		assert_equal("<mover><mo>=</mo><mo>&rightarrow;</mo></mover>", smml('\stackrel\to='))
		assert_equal("<mover><mn>2</mn><mn>1</mn></mover>", smml('\stackrel12'))
	end

	def test_comment
		assert_equal("<mi>a</mi>", smml('a%b'))
	end

	def test_entity
		p = Parser.new
		e = assert_raises(ParseError){smml('\entity{therefore}', false, p)}
		assert_equal(["Unregistered entity.", '\entity{', "therefore}"], parse_error(e))

		p.unsecure_entity = true
		assert_equal("<mo>&therefore;</mo>", smml('\entity{therefore}', false, p))

		p.unsecure_entity = false
		e = assert_raises(ParseError){smml('\entity{therefore}', false, p)}
		assert_equal(["Unregistered entity.", '\entity{', "therefore}"], parse_error(e))

		p.add_entity(['therefore'])
		assert_equal("<mo>&therefore;</mo>", smml('\entity{therefore}', false, p))
	end

	def test_backslash
		assert_equal("<br xmlns='http://www.w3.org/1999/xhtml' />", smml('\\\\'))
	end

	def test_macro
		macro = <<'EOS'
\newcommand{\root}[2]{\sqrt[#1]{#2}}
\newcommand{\ROOT}[2]{\sqrt[#1]#2}
\newenvironment{braced}[2]{\left#1}{\right#2}
\newenvironment{sq}[2]{\sqrt[#2]{#1}}{\sqrt#2}
\newcommand{\R}{\mathbb R}
\newenvironment{BB}{\mathbb A}{\mathbb B}
EOS
		p = Parser.new
		p.macro.parse(macro)

		assert_equal("<mroot><mrow><mn>2</mn></mrow><mn>1</mn></mroot>", smml('\root12', false, p))
		assert_equal("<mroot><mrow><mn>34</mn></mrow><mn>12</mn></mroot>", smml('\root{12}{34}', false, p))
		assert_equal("<mroot><mn>3</mn><mn>12</mn></mroot><mn>4</mn>", smml('\ROOT{12}{34}', false, p))
		assert_parse_error('Error in macro(Need more parameter. "").', '', '\root'){smml('\root', false, p)}

		assert_equal("<mfenced close=')' open='|'><mrow><mfrac><mn>1</mn><mn>2</mn></mfrac></mrow></mfenced>", smml('\begin{braced}{|}{)}\frac12\end{braced}', false, p))
		assert_equal("<mroot><mrow><mn>12</mn></mrow><mn>34</mn></mroot><mi>a</mi><msqrt><mn>3</mn></msqrt><mn>4</mn>", smml('\begin{sq}{12}{34}a\end{sq}', false, p))
		assert_parse_error("Need more parameter.", '\begin{braced}', ""){smml('\begin{braced}', false, p)}
		assert_parse_error('Matching \end not exist.', '\begin{braced}', "123"){smml('\begin{braced}123', false, p)}
		assert_parse_error("Environment mismatched.", '\begin{braced}123\end', '{brace}'){smml('\begin{braced}123\end{brace}', false, p)}
		assert_equal("<mrow><mi>&Ropf;</mi></mrow>", smml('\R', false, p))
		assert_equal("<mrow><mi>&Aopf;</mi></mrow><mrow><mi>&Bopf;</mi></mrow>", smml('\begin{BB}\end{BB}', false, p))
	end

	def test_macro_circular_reference
		macro = <<'EOT'
\newcommand{\C}{\C}
\newenvironment{E}{\begin{E}}{\end{E}}
\newcommand{\D}{\begin{F}\end{F}}
\newenvironment{F}{\D}{}
EOT
		ps = Parser.new
		ps.macro.parse(macro)

		e = assert_raises(ParseError){smml('\C', false, ps)}
		assert_equal(["Circular reference.", "", '\C'], parse_error(e))

		e = assert_raises(ParseError){smml('\begin{E}\end{E}', false, ps)}
		assert_equal(["Circular reference.", "", '\begin{E}\end{E}'], parse_error(e))

		e = assert_raises(ParseError){smml('\D', false, ps)}
		assert_equal(["Circular reference.", "", '\D'], parse_error(e))

		e = assert_raises(ParseError){smml('\begin{F}\end{F}', false, ps)}
		assert_equal(["Circular reference.", "", '\begin{F}\end{F}'], parse_error(e))
	end

	def test_macro_non_circular_reference
		macro = <<'EOT'
\newcommand{\C}{\dummy}
\newenvironment{E}{\dummy}{}
EOT
		ps = Parser.new
		ps.macro.parse(macro)

		e = assert_raises(ParseError){smml('\C', false, ps)}
		assert_equal(['Error in macro(Undefined command. "\dummy").', "", '\C'], parse_error(e))
		e = assert_raises(ParseError){smml('\C', false, ps)}
		assert_equal(['Error in macro(Undefined command. "\dummy").', "", '\C'], parse_error(e))

		e = assert_raises(ParseError){smml('\begin{E}\end{E}', false, ps)}
		assert_equal(['Error in macro(Undefined command. "\dummy").', '', '\begin{E}\end{E}'], parse_error(e))
		e = assert_raises(ParseError){smml('\begin{E}\end{E}', false, ps)}
		assert_equal(['Error in macro(Undefined command. "\dummy").', "", '\begin{E}\end{E}'], parse_error(e))
	end

	def test_macro_with_option
		macro = <<'EOS'
\newcommand{\opt}[1][x]{#1}
\newcommand{\optparam}[2][]{#1#2}
\newenvironment{newenv}[1][x]{#1}{#1}
\newenvironment{optenv}[2][]{#1}{#2}
EOS

		p = Parser.new
		p.macro.parse(macro)

		assert_equal("<mi>x</mi><mi>a</mi>", smml('\opt a', false, p))
		assert_equal("<mn>0</mn><mi>a</mi>", smml('\opt[0] a', false, p))
		assert_equal("<mi>a</mi>", smml('\optparam a', false, p))
		assert_equal("<mn>0</mn><mi>a</mi>", smml('\optparam[0] a', false, p))

		assert_equal("<mi>x</mi><mi>a</mi><mi>x</mi>", smml('\begin{newenv}a\end{newenv}', false, p))
		assert_equal("<mn>0</mn><mi>a</mi><mn>0</mn>", smml('\begin{newenv}[0]a\end{newenv}', false, p))
		assert_equal("<mi>a</mi><mn>0</mn>", smml('\begin{optenv}0a\end{optenv}', false, p))
		assert_equal("<mn>0</mn><mi>a</mi><mn>1</mn>", smml('\begin{optenv}[0]1a\end{optenv}', false, p))
	end

	def test_matrix_env
		assert_equal("<mtable><mtr><mtd /><mtd /><mtd /></mtr><mtr><mtd /><mtd /></mtr></mtable>", smml('\begin{matrix}&&\\\\&\end{matrix}'))
		assert_parse_error("Environment mismatched.", '\begin{matrix}&&\\\\&\end', "{mat}"){smml('\begin{matrix}&&\\\\&\end{mat}')}
		assert_parse_error("Matching \\end not exist.", '\begin{matrix}&&\\\\&', ''){smml('\begin{matrix}&&\\\\&')}
		assert_equal("<mtable><mtr><mtd><mtable><mtr><mtd><mi>a</mi></mtd><mtd><mi>b</mi></mtd></mtr><mtr><mtd><mi>c</mi></mtd><mtd><mi>d</mi></mtd></mtr></mtable></mtd><mtd><mn>1</mn></mtd></mtr><mtr><mtd><mn>0</mn></mtd><mtd><mn>1</mn></mtd></mtr></mtable>", smml('\begin{matrix}\begin{matrix}a&b\\\\c&d\end{matrix}&1\\\\0&1\\\\\end{matrix}'))
		assert_equal("<mtable />", smml('\begin{matrix}\end{matrix}'))
		assert_equal("<mtable rowlines='solid none solid'><mtr /><mtr><mtd><mi>a</mi></mtd></mtr><mtr><mtd><mi>b</mi></mtd></mtr><mtr /></mtable>", smml('\begin{matrix}\hline a\\\\b\\\\\hline\end{matrix}'))

		assert_equal("<mtable />", smml('\begin{smallmatrix}\end{smallmatrix}'))
		assert_equal("<mfenced close=')' open='('><mrow><mtable /></mrow></mfenced>", smml('\begin{pmatrix}\end{pmatrix}'))
		assert_equal("<mfenced close=']' open='['><mrow><mtable /></mrow></mfenced>", smml('\begin{bmatrix}\end{bmatrix}'))
		assert_equal("<mfenced close='}' open='{'><mrow><mtable /></mrow></mfenced>", smml('\begin{Bmatrix}\end{Bmatrix}'))
		assert_equal("<mfenced close='|' open='|'><mrow><mtable /></mrow></mfenced>", smml('\begin{vmatrix}\end{vmatrix}'))
		assert_equal("<mfenced close='&DoubleVerticalBar;' open='&DoubleVerticalBar;'><mrow><mtable /></mrow></mfenced>", smml('\begin{Vmatrix}\end{Vmatrix}'))
	end

	def test_safe_mode
		Thread.start do
			$SAFE=1
			assert_nothing_raised{smml('\alpha'.taint)}
		end.join
	end

	def test_symbol
		assert_equal("<mo><mfrac linethickness='0' mathsize='1%'><mo>&prec;</mo><mo>&ne;</mo></mfrac></mo>", smml('\precneqq'))
	end
end
