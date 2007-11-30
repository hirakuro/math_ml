# Test for math_ml/util.rb
#
# Copyright (C) 2006, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.

require "test/unit"
require "math_ml_test_util"
require "math_ml"
require "math_ml/util"

class TC_MathML_Util < Test::Unit::TestCase
	include MathML::Util

	def test_escapeXML
		assert_equal("&lt;&gt;&amp;&quot;&apos;", escapeXML("<>&\"'"))
		assert_equal("\n", escapeXML("\n"))
		assert_equal("<br />\n", escapeXML("\n", true))

		assert_equal("&lt;&gt;&amp;&quot;&apos;", MathML::Util.escapeXML("<>&\"'"))
		assert_equal("\n", MathML::Util.escapeXML("\n"))
		assert_equal("<br />\n", MathML::Util.escapeXML("\n", true))
	end

	def test_collect_regexp
		assert_equal(/#{/a/}|#{/b/}|#{/c/}/, collect_regexp([/a/, /b/, /c/]))
		assert_equal(/#{/a/}|#{/b/}|#{/c/}/, collect_regexp([[/a/, /b/, /c/]]))
		assert_equal(/(?!)/, collect_regexp([]))
		assert_equal(/#{/a/}/, collect_regexp(/a/))

		assert_equal(/#{/a/}|#{/b/}|#{/c/}/, MathML::Util.collect_regexp([/a/, /b/, /c/]))
		assert_equal(/#{/a/}|#{/b/}|#{/c/}/, MathML::Util.collect_regexp([[/a/, /b/, /c/]]))
		assert_equal(/(?!)/, MathML::Util.collect_regexp([]))
		assert_equal(/#{/a/}/, MathML::Util.collect_regexp(/a/))

		assert_equal(/#{/a/}|#{/b/}/, MathML::Util.collect_regexp([nil, /a/, "text", /b/]))

		assert_equal(/#{/a/}|#{/b/}|#{/c/}/, MathML::Util.collect_regexp([nil, [/a/, [/b/, /c/]]]))
	end

	def test_invalid_re
		assert_equal(/(?!)/, MathML::Util::INVALID_RE)
	end
end

class TC_MathData < Test::Unit::TestCase
	include MathML::Util

	def test_update
		m = MathData.new
		m.math_list << "ml1"
		m.msrc_list << "sl1"
		m.dmath_list << "dml1"
		m.dsrc_list << "dsl1"
		m.escape_list << "el1"
		m.esrc_list << "es1"
		m.user_list << "ul1"
		m.usrc_list << "usl1"
		assert_equal(["ml1"], m.math_list)
		assert_equal(["sl1"], m.msrc_list)
		assert_equal(["dml1"], m.dmath_list)
		assert_equal(["dsl1"], m.dsrc_list)
		assert_equal(["el1"], m.escape_list)
		assert_equal(["es1"], m.esrc_list)
		assert_equal(["ul1"], m.user_list)
		assert_equal(["usl1"], m.usrc_list)

		m2 = MathData.new
		m2.math_list << "ml2"
		m2.msrc_list << "sl2"
		m2.dmath_list << "dml2"
		m2.dsrc_list << "dsl2"
		m2.escape_list << "el2"
		m2.esrc_list << "es2"
		m2.user_list << "ul2"
		m2.usrc_list << "usl2"

		m.update(m2)

		assert_equal(["ml1", "ml2"], m.math_list)
		assert_equal(["sl1",  "sl2"], m.msrc_list)
		assert_equal(["dml1", "dml2"], m.dmath_list)
		assert_equal(["dsl1", "dsl2"], m.dsrc_list)
		assert_equal(["el1", "el2"], m.escape_list)
		assert_equal(["es1", "es2"], m.esrc_list)
		assert_equal(["ul1", "ul2"], m.user_list)
		assert_equal(["usl1", "usl2"], m.usrc_list)
	end
end

class TC_SimpleLaTeX < Test::Unit::TestCase
	include MathML::Util
	include Util4TC_MathML

	def strip_math(s)
		strip(s)[/<math.*?>(.*)<\/math>/m, 1]
	end

	def sma(a) # Stripped Mathml Array
		r = []
		a.each do |i|
			r << strip_math(i.to_s)
		end
		r
	end

	def assert_data(src,
			expected_math, expected_src,
			expected_dmath, expected_dsrc,
			expected_escaped, expected_esrc,
			expected_encoded, expected_decoded,
			simple_latex = SimpleLaTeX)
		encoded, data = simple_latex.encode(src)

		data.math_list.each do |i|
			assert_equal("inline", i.attributes[:display])
		end
		data.dmath_list.each do |i|
			assert_equal("block", i.attributes[:display])
		end

		assert_equal(expected_math, sma(data.math_list))
		assert_equal(expected_src, data.msrc_list)
		assert_equal(expected_dmath, sma(data.dmath_list))
		assert_equal(expected_dsrc, data.dsrc_list)
		assert_equal(expected_escaped, data.escape_list)
		assert_equal(expected_esrc, data.esrc_list)
		assert_equal(expected_encoded, encoded)
		assert_equal(expected_decoded, simple_latex.decode(encoded, data))
	end

	def test_math
		assert_data("a\n$\nb\n$\nc\\(\nd\n\\)e",
			["<mi>b</mi>", "<mi>d</mi>"],
			["$\nb\n$", "\\(\nd\n\\)"],
			[], [], [], [],
			"a\n\001m0\001\nc\001m1\001e",
			"a\n<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>\nc<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>d</mi></math>e")

		assert_data('$\\$$',
			["<mo>$</mo>"],
			['$\$$'], [], [], [], [], "\001m0\001",
			"<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mo>$</mo></math>")
	end

	def test_dmath
		assert_data("a\n$$\nb\n$$\nc\\[\nd\n\\]e",
			[], [],
			["<mi>b</mi>", "<mi>d</mi>"],
			["$$\nb\n$$", "\\[\nd\n\\]"],
			[], [],
			"a\n\001d0\001\nc\001d1\001e",
			"a\n<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>\nc<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>d</mi></math>e")
	end

	def test_math_and_dmath
		assert_data('a$b$c$$d$$e\(f\)g\[h\]i',
			["<mi>b</mi>", "<mi>f</mi>"],
			["$b$", '\(f\)'],
			["<mi>d</mi>", "<mi>h</mi>"],
			["$$d$$", '\[h\]'],
			[], [],
			"a\001m0\001c\001d0\001e\001m1\001g\001d1\001i",
			"a<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>c<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>d</mi></math>e<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>f</mi></math>g<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>h</mi></math>i")
	end

	def test_escapeing
		assert_data('a\bc\d\e', [], [], [], [], ['b', 'd', 'e'], ['\b', '\d', '\e'], "a\001e0\001c\001e1\001\001e2\001", 'abcde')
		assert_data('\$a$$b$$', [], [], ["<mi>b</mi>"], ["$$b$$"], [%[$]], ['\$'], "\001e0\001a\001d0\001",
			"$a<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>")

		assert_data("\\<\\\n", [], [], [], [], ["&lt;", "<br />\n"], ["\\<", "\\\n"], "\001e0\001\001e1\001", "&lt;<br />\n")
	end

	def test_through
		s = SimpleLaTeX.new(:through_list=>[/\{\{.*\}\}/, /\(.*\)/])
		assert_data("{{$a$}}($b$)", [], [], [], [], [], [], "{{$a$}}($b$)", "{{$a$}}($b$)", s)

		s = SimpleLaTeX.new(:through_list=>/\{.*\}/)
		assert_data("{$a$}", [], [], [], [], [], [], "{$a$}", "{$a$}", s)
	end

	def test_options_parser
		ps = MathML::LaTeX::Parser.new
		ps.macro.parse('\newcommand{\test}{t}')
		s = SimpleLaTeX.new(:parser=>ps)
		assert_data('$\test$', ["<mi>t</mi>"], ['$\test$'], [], [], [], [], "\001m0\001",
			"<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>t</mi></math>", s)
	end

	def test_options_escape
		s = SimpleLaTeX.new(:escape_list=>[/\/(.)/, /(\^.)/])
		assert_data('\$a$', ["<mi>a</mi>"], ['$a$'], [], [], [], [], "\\\001m0\001",
			"\\<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>a</mi></math>", s)
		assert_data(%[/$a/$], [], [], [], [], [%[$], %[$]], [%[/$], %[/$]], "\001e0\001a\001e1\001", "$a$", s)
		assert_data('^\(a^\)', [], [], [], [], ['^\\', '^\\'], ['^\\', '^\\'], "\001e0\001(a\001e1\001)", '^\(a^\)', s)

		s = SimpleLaTeX.new(:escape_list=>/_(.)/)
		assert_data("_$a$", [], [], [], [], ['$'], ["_$"], %[\001e0\001a$], '$a$', s)
	end

	def test_options_delimiter
		s = SimpleLaTeX.new(:delimiter=>"\002\003")
		assert_data("a$b$c", ["<mi>b</mi>"], ["$b$"], [], [], [], [], "a\002\003m0\002\003c",
			"a<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>c", s)

		s = SimpleLaTeX.new(:delimiter=>"$")
		assert_data("a$b$c", ["<mi>b</mi>"], ["$b$"], [], [], [], [], "a$m0$c",
			"a<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>c", s)
	end

	def test_options_math_env_list
		s = SimpleLaTeX.new(:math_env_list=>/%(.*?)%/, :dmath_env_list=>/\[(.*?)\]/)
		assert_data("a$b$c%d%e[f]", ["<mi>d</mi>"], ["%d%"], ["<mi>f</mi>"], ["[f]"], [], [],
			"a$b$c\001m0\001e\001d0\001",
			"a$b$c<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>d</mi></math>e<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>f</mi></math>", s)

		s = SimpleLaTeX.new(:math_env_list=>[/!(.*?)!/, /"(.*)"/], :dmath_env_list=>[/\#(.*)\#/, /&(.*)&/])
		assert_data('a!b!c"d"e#f#g&h&i',
			["<mi>b</mi>", "<mi>d</mi>"], ['!b!', '"d"'],
			["<mi>f</mi>", "<mi>h</mi>"], ['#f#', '&h&'],
			[], [],
			"a\001m0\001c\001m1\001e\001d0\001g\001d1\001i",
			"a<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>c<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>d</mi></math>e<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>f</mi></math>g<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>h</mi></math>i", s)
	end

	def test_options_through_list
		s = SimpleLaTeX.new(:through_list=>[/<%=.*?%>/m, /\(\(.*?\)\)/m])
		assert_data("<%=$a$%>(($b$))", [], [], [], [], [], [], "<%=$a$%>(($b$))", "<%=$a$%>(($b$))", s)

		s = SimpleLaTeX.new(:through_list=>/<%=.*?%>/)
		assert_data("<%=$a$%>", [], [], [], [], [], [], "<%=$a$%>", "<%=$a$%>", s)
	end

	def test_empty_list
		s = SimpleLaTeX.new(:through_list=>[])
		assert_data("$a$", ["<mi>a</mi>"], [%[$a$]], [], [], [], [], "\001m0\001",
			"<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>a</mi></math>", s)
	end

	def test_options_without_parse
		s = SimpleLaTeX.new(:without_parse=>true)
		encoded, data = s.encode("$a$ $$b$$")
		assert_equal([], data.math_list)
		assert_equal(["$a$"], data.msrc_list)
		assert_equal([], data.dmath_list)
		assert_equal(["$$b$$"], data.dsrc_list)
		assert_equal("\001m0\001 \001d0\001", encoded)

		s.parse(data)
		assert_equal("inline", data.math_list[0].attributes[:display])
		assert_equal("block", data.dmath_list[0].attributes[:display])
		assert_equal(["<mi>a</mi>"], sma(data.math_list))
		assert_equal(["<mi>b</mi>"], sma(data.dmath_list))
		assert_equal("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>a</mi></math> <math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>", s.decode(encoded, data))
	end

	def test_set_encode_proc
		s = SimpleLaTeX.new
		s.set_encode_proc(/\{\{/) do |scanner|
			if scanner.scan(/\{\{(.*?)\}\}/m)
				"<%=#{scanner[1]}%>"
			end
		end
		src = "{{$a$}}{{$$b$$}}{{"
		assert_data(src, [], [], [], [], [], [], "\001u0\001\001u1\001{{", "<%=$a$%><%=$$b$$%>{{", s)
		encoded, data = s.encode(src)
		assert_equal(["<%=$a$%>", "<%=$$b$$%>"], data.user_list)
		assert_equal(["{{$a$}}", "{{$$b$$}}"], data.usrc_list)

		s.set_encode_proc(/\{\{/) do |scanner|
		end
		src = "{{a"
		assert_data(src, [], [], [], [], [], [], "{{a", "{{a", s)
		encoded, data = s.encode(src)
		assert_equal([], data.user_list)
		assert_equal([], data.usrc_list)
	end

	def test_encode_proc_with_arrayed_regexp
		s = SimpleLaTeX.new
		src = "{{a}}((b)){{(("
		encoded, data = s.encode(src, /\{\{/, /\(\(/) do |scanner|
			case
			when scanner.scan(/\{\{.*?\}\}/)
				"brace"
			when scanner.scan(/\(\(.*?\)\)/)
				"parenthesis"
			end
		end
		assert_equal("\001u0\001\001u1\001{{((", encoded)
		assert_equal("braceparenthesis{{((", s.decode(encoded, data))

		s.set_encode_proc(/\{\{/, /\(\(/) do |scanner|
			case
			when scanner.scan(/\{\{.*?\}\}/)
				"brace"
			when scanner.scan(/\(\(.*?\)\)/)
				"parenthesis"
			end
		end
		encoded, data = s.encode(src)
		assert_equal("\001u0\001\001u1\001{{((", encoded)
		assert_equal("braceparenthesis{{((", s.decode(encoded, data))
	end

	def test_encode_with_proc
		s = SimpleLaTeX.new
		src = "{{$a$}}{{$$b$$}}{{"
		encoded, data = s.encode(src, /\{\{/) do |scanner|
			if scanner.scan(/\{\{(.*?)\}\}/m)
				"<%=#{scanner[1]}%>"
			end
		end
		assert_equal([], data.math_list)
		assert_equal([], data.dmath_list)
		assert_equal([], data.escape_list)
		assert_equal("\001u0\001\001u1\001{{", encoded)
		assert_equal("<%=$a$%><%=$$b$$%>{{", s.decode(encoded, data))
	end

	def test_encode_with_proc_with_encode_proc_set
		s = SimpleLaTeX.new
		src = "{{$a$}}{{$$b$$}}{{"
		s.set_encode_proc(/\{\{/) do |scanner|
			if scanner.scan(/\{\{(.*?)\}\}/m)
				"<%=#{scanner[1]}%>"
			end
		end
		encoded, data = s.encode(src, /\{\{/) do |scanner|
			if scanner.scan(/\{\{(.*?)\}\}/m)
				"<$=#{scanner[1]}$>"
			end
		end
		assert_equal([], data.math_list)
		assert_equal([], data.dmath_list)
		assert_equal([], data.escape_list)
		assert_equal("\001u0\001\001u1\001{{", encoded)
		assert_equal("<$=$a$$><$=$$b$$$>{{", s.decode(encoded, data))
	end

	def test_unencode
		src = "$\na\n$\n$$\nb\n$$"
		s = SimpleLaTeX.new
		encoded, data = s.encode(src)
		assert_equal("$<br />\na<br />\n$\n$$<br />\nb<br />\n$$", s.unencode(encoded, data))

		s = SimpleLaTeX.new(:delimiter=>"$")
		e, d = s.encode("$a$")
		assert_equal("$a$", s.unencode(e, d))
	end

	def test_set_rescue_proc
		src = '$a\test$ $$b\dummy$$'
		s = SimpleLaTeX.new
		encoded, data = s.encode(src)
		assert_equal("<br />\nUndefined command.<br />\n<code>a<strong>\\test</strong></code><br />", data.math_list[0])
		assert_equal("<br />\nUndefined command.<br />\n<code>b<strong>\\dummy</strong></code><br />", data.dmath_list[0])

		s.set_rescue_proc do |e|
			e
		end
		encoded, data = s.encode(src)
		assert_kind_of(MathML::LaTeX::ParseError, data.math_list[0])
		assert_equal("a", data.math_list[0].done)
		assert_kind_of(MathML::LaTeX::ParseError, data.dmath_list[0])
		assert_equal("b", data.dmath_list[0].done)
	end

	def test_decode_with_proc
		s = SimpleLaTeX.new
		encoded, data = s.encode('$a$$b$$$c$$$$d$$\e\\\\')
		r = s.decode(encoded, data) do |item, opt|
			case opt[:type]
			when :dmath
				assert_equal("block", item.attributes[:display])
				i = strip_math(item.to_s)
			when :math
				assert_equal("inline", item.attributes[:display])
				i = strip_math(item.to_s)
			else
				i = item
			end
			r = "t#{opt[:type]}i#{opt[:index]}s#{opt[:src]}#{i}"
		end
		assert_equal("tmathi0s$a$<mi>a</mi>tmathi1s$b$<mi>b</mi>tdmathi0s$$c$$<mi>c</mi>tdmathi1s$$d$$<mi>d</mi>tescapei0s\\eetescapei1s\\\\\\", r)

		r = s.decode(encoded, data) do |item, opt|
			nil
		end
		assert_equal(s.decode(encoded, data), r)

		s.set_encode_proc(/\{\{/) do |scanner|
			"<%=#{scanner[1]}%>" if scanner.scan(/\{\{(.*?)\}\}/m)
		end
		encoded, data = s.encode("{{a}}{{")
		r = s.decode(encoded, data) do |item, opt|
			assert_equal("<%=a%>", item)
			assert_equal(:user, opt[:type])
			assert_equal(0, opt[:index])
			assert_equal("{{a}}", opt[:src])
			nil
		end
		assert_equal("<%=a%>{{", r)

		s.set_decode_proc do |item, opt|
			"dummy"
		end
		assert_equal("dummy{{", s.decode(encoded, data))
		r = s.decode(encoded, data) do |item, opt|
			nil
		end
		assert_equal("<%=a%>{{", r)
	end

	def test_set_decode_proc
		s = SimpleLaTeX.new
		src = '$a$$b$$$c$$$$d$$\e\\\\'
		encoded, data = s.encode(src)
		original_decoded = s.decode(encoded, data)
		s.set_decode_proc do |item, opt|
			case opt[:type]
			when :dmath
				assert_equal("block", item.attributes[:display])
				i = strip_math(item.to_s)
			when :math
				assert_equal("inline", item.attributes[:display])
				i = strip_math(item.to_s)
			else
				i = item
			end
			r = "t#{opt[:type]}i#{opt[:index]}s#{opt[:src]}#{i}"
		end
		encoded, data = s.encode(src)
		r = s.decode(encoded, data)
		assert_equal("tmathi0s$a$<mi>a</mi>tmathi1s$b$<mi>b</mi>tdmathi0s$$c$$<mi>c</mi>tdmathi1s$$d$$<mi>d</mi>tescapei0s\\eetescapei1s\\\\\\", r)

		s.reset_decode_proc
		assert_equal(original_decoded, s.decode(encoded, data))
	end

	def test_unencode_with_proc
		s = SimpleLaTeX.new
		src = '$a$$b$$$c$$$$d$$\e\\\\'
		encoded, data = s.encode(src)
		r = s.unencode(encoded, data) do |item, opt|
			r = "t#{opt[:type]}i#{opt[:index]}#{item.to_s}"
		end
		assert_equal("tmathi0$a$tmathi1$b$tdmathi0$$c$$tdmathi1$$d$$tescapei0\\etescapei1\\\\", r)

		r = s.unencode(encoded, data) do |item, opt|
			nil
		end
		assert_equal(s.unencode(encoded, data), r)

		s.set_encode_proc(/\{\{/) do |scanner|
			"<%=#{scanner[1]}%>" if scanner.scan(/\{\{(.*?)\}\}/m)
		end
		encoded, data = s.encode("{{a}}{{")
		r = s.unencode(encoded, data) do |item, opt|
			assert_equal("{{a}}", item)
			assert_equal(:user, opt[:type])
			assert_equal(0, opt[:index])
			nil
		end
		assert_equal("{{a}}{{", r)
	end

	def test_unencode_proc
		s = SimpleLaTeX.new
		src = '$a$$b$$$c$$$$d$$\e\\\\'
		encoded, data = s.encode(src)
		original_unencoded = s.unencode(encoded, data)

		s.set_unencode_proc do |item, opt|
			r = "t#{opt[:type]}i#{opt[:index]}#{item.to_s}"
		end
		r = s.unencode(encoded, data)
		assert_equal("tmathi0$a$tmathi1$b$tdmathi0$$c$$tdmathi1$$d$$tescapei0\\etescapei1\\\\", r)

		s.set_unencode_proc do |item, opt|
			nil
		end
		assert_equal(original_unencoded, s.unencode(encoded, data))

		s.set_encode_proc(/\{\{/) do |scanner|
			"<%=#{scanner[1]}%>" if scanner.scan(/\{\{(.*?)\}\}/m)
		end
		encoded, data = s.encode("{{a}}{{")
		s.set_unencode_proc do |item, opt|
			assert_equal("{{a}}", item)
			assert_equal(:user, opt[:type])
			assert_equal(0, opt[:index])
			nil
		end
		r = s.unencode(encoded, data)
		assert_equal("{{a}}{{", r)
	end

	def test_reset_unencode_proc
		s = SimpleLaTeX.new
		s.set_unencode_proc do |item, opt|
			"dummy"
		end
		encoded, data = s.encode("$a$ $$b$$")
		assert_equal("dummy dummy", s.unencode(encoded, data))

		s.reset_unencode_proc
		assert_equal("$a$ $$b$$", s.unencode(encoded, data))
	end

	def test_unencode_escaping
		s = SimpleLaTeX.new
		src = %[$<>&'"\n$ $$<>&"'\n$$]
		encoded, data = s.encode(src)
		assert_equal("$&lt;&gt;&amp;&apos;&quot;<br />\n$ $$&lt;&gt;&amp;&quot;&apos;<br />\n$$", s.unencode(encoded, data))
		assert_equal(src, s.unencode(encoded, data, true), "without escaping")
	end

	def test_decode_without_parsed
		s = SimpleLaTeX.new
		src = '$a$$$b$$\a'
		encoded, data = s.encode(src)
		assert_equal("$a$$$b$$a", s.decode(encoded, data, true))
		s.decode(encoded, data, true) do |item, opt|
			case opt[:type]
			when :math
				assert_equal("$a$", item)
			when :dmath
				assert_equal("$$b$$", item)
			when :escape
				assert_equal("a", item)
			end
		end

		encoded, data = s.encode("$<\n$ $$<\n$$")
		assert_equal("$&lt;<br />\n$ $$&lt;<br />\n$$", s.decode(encoded, data, true))
	end

	def test_decode_partial
		s = SimpleLaTeX.new
		encoded, data = s.encode("$a$$b$")
		assert_equal("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>a</mi></math><math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>", s.decode_partial(:math, encoded, data))

		s.set_encode_proc(/\\</) do |scanner|
			if scanner.scan(/\\<(.)(.*?)\1>/)
				scanner[2]
			end
		end
		src='$a$$$b$$\c\<.$d$.>'
		encoded, data = s.encode(src)
		assert_equal("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>a</mi></math>\001d0\001\001e0\001\001u0\001", s.decode_partial(:math, encoded, data))
		assert_equal("\001m0\001<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>\001e0\001\001u0\001", s.decode_partial(:dmath, encoded, data))
		assert_equal("\001m0\001\001d0\001c\001u0\001", s.decode_partial(:escape, encoded, data))
		assert_equal("\001m0\001\001d0\001\001e0\001$d$", s.decode_partial(:user, encoded, data))

		r = s.decode_partial(:math, encoded, data) do |item, opt|
			assert_equal(:math, opt[:type])
			assert_equal("$a$", opt[:src])
			assert_equal("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>a</mi></math>", item.to_s)
			item
		end
		assert_equal("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>a</mi></math>\001d0\001\001e0\001\001u0\001", r)

		r = s.decode_partial(:dmath, encoded, data) do |item, opt|
			assert_equal(:dmath, opt[:type])
			assert_equal("$$b$$", opt[:src])
			assert_equal("<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>", item.to_s)
			item
		end
		assert_equal("\001m0\001<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mi>b</mi></math>\001e0\001\001u0\001", r)

		r = s.decode_partial(:escape, encoded, data) do |item, opt|
			assert_equal(:escape, opt[:type])
			assert_equal("\\c", opt[:src])
			assert_equal("c", item)
			item
		end
		assert_equal("\001m0\001\001d0\001c\001u0\001", r)

		r = s.decode_partial(:user, encoded, data) do |item, opt|
			assert_equal(:user, opt[:type])
			assert_equal("\\<.$d$.>", opt[:src])
			assert_equal("$d$", item)
			item
		end
		assert_equal("\001m0\001\001d0\001\001e0\001$d$", r)

		s = SimpleLaTeX.new
		encoded, data = s.encode("\\a")
		assert_equal("a", s.decode_partial(:escape, encoded, data))
		r = s.decode_partial(:escape, encoded, data) do |item, opt|
		end
		assert_equal("\001e0\001", r)

		s = SimpleLaTeX.new(:delimiter=>"$")
		encoded, data = s.encode("$a$")
		assert_match(/^<math.*<\/math>/m, s.decode_partial(:math, encoded, data))
	end

	def test_regexp_order
		s = SimpleLaTeX.new
		s.set_encode_proc(/\$/) do |sc|
			if sc.scan(/\$(.*)\z/)
				sc[1]+"is rest"
			end
		end

		encoded, data = s.encode("$a$$b")
		assert_equal("\001m0\001\001u0\001", encoded)
	end

	def test_eqnarray
		s = SimpleLaTeX.new
		src = <<'EOT'
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
			if scanner.scan(MathML::Util::EQNARRAY_RE)
				s.parse_eqnarray(scanner[1])
			end
		end
		assert_equal("test\n\001u0\001\nend\n", encoded)
		assert_equal("test\n<math display='block' xmlns='http://www.w3.org/1998/Math/MathML'><mtable><mtr><mtd><mi>a</mi></mtd><mtd><mo>=</mo></mtd><mtd><mi>b</mi></mtd></mtr><mtr><mtd><mi>c</mi></mtd><mtd><mo>=</mo></mtd><mtd><mi>d</mi></mtd></mtr></mtable></math>\nend\n", s.decode(encoded, data).gsub(/>\s*</, "><"))

		encoded, data = s.encode('\begin{eqnarray}a\end{eqnarray}', MathML::Util::EQNARRAY_RE) do |scanner|
			s.parse_eqnarray(scanner[1]) if scanner.scan(MathML::Util::EQNARRAY_RE)
		end
		assert_equal("<br />\nNeed more column.<br />\n<code>\\begin{eqnarray}a<strong>\\end{eqnarray}</strong></code><br />", s.decode(encoded, data))
	end

	def test_single_command
		s = SimpleLaTeX.new
		encoded, data = s.encode(%q[\alpha\|\<\>\&\"\'\test], MathML::Util::SINGLE_COMMAND_RE) do |scanner|
			if scanner.scan(MathML::Util::SINGLE_COMMAND_RE)
				s.parse_single_command(scanner.matched)
			end
		end
		assert_equal("\001u0\001\001e0\001\001e1\001\001e2\001\001e3\001\001e4\001\001e5\001\001u1\001", encoded)
		assert_equal("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>&alpha;</mi></math>|&lt;&gt;&amp;&quot;&apos;test", s.decode(encoded, data))
		encoded, data = s.encode('\alpha test', MathML::Util::SINGLE_COMMAND_RE) do |scanner|
			if scanner.scan(MathML::Util::SINGLE_COMMAND_RE)
				s.parse_single_command(scanner.matched)
			end
		end
		assert_equal("\001u0\001test", encoded)
		assert_equal("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>&alpha;</mi></math>test", s.decode(encoded, data))

		encoded, data = s.encode('\alpha  test', MathML::Util::SINGLE_COMMAND_RE) do |scanner|
			if scanner.scan(MathML::Util::SINGLE_COMMAND_RE)
				s.parse_single_command(scanner.matched)
			end
		end
		assert_equal("\001u0\001 test", encoded)
		assert_equal("<math display='inline' xmlns='http://www.w3.org/1998/Math/MathML'><mi>&alpha;</mi></math> test", s.decode(encoded, data))

		encoded, data = s.encode("\\alpha\ntest", MathML::Util::SINGLE_COMMAND_RE) do |scanner|
			if scanner.scan(MathML::Util::SINGLE_COMMAND_RE)
				s.parse_single_command(scanner.matched)
			end
		end
		assert_equal("\001u0\001\ntest", encoded)
	end

	def test_encode_append
		s = SimpleLaTeX.new
		encoded, data = s.encode('$a$')
		encoded, data = s.encode('$b$', data)
		assert_equal("\001m1\001", encoded)
		assert_equal(["$a$", '$b$'], data.msrc_list)
		assert_equal(2, data.math_list.size)
		assert_equal("<mi>a</mi>", strip_mathml(data.math_list[0].to_s))
		assert_equal("<mi>b</mi>", strip_mathml(data.math_list[1].to_s))

		encoded, data = s.encode('a', data, /a/) do |sc|
			sc.scan(/a/)
		end
		assert_equal("\001u0\001", encoded)
		assert_equal(["$a$", '$b$'], data.msrc_list)
		assert_equal(["a"], data.usrc_list)

		encoded, data = s.encode('a', nil, /a/) do |s|
			s.scan(/a/)
		end
		assert_equal("\001u0\001", encoded)
		assert_equal(["a"], data.usrc_list)
	end
end
