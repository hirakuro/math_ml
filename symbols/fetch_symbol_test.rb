#!/usr/bin/ruby

require "test/unit"
require "symbols/fetch_symbol"
require "test/math_ml_test_util"
require "math_ml"

class TC_Misc < Test::Unit::TestCase
	def test_brace_nest
		assert_equal("{1.{2.}2.}1.", brace_nest("{{}}"))
		assert_equal("{1.{2.}2.{2.}2.}1.", brace_nest("{{}{}}"))
	end
end

class TC_FetchSymbol < Test::Unit::TestCase
	include Util4TC_MathML
	LIST = <<'EOT'
\{ subsup o-
\& subsup o:amp
\varepsilon subsup I:
\Gamma subsup i:
\ensuremath subsup v
\log subsup i-
\lim underover i-
\dagger subsup 
\braceld subsup o=x25dc # dummy
\relbar subsup o--
\precneqq subsup o-<mfrac mathsize='1%' linethickness='0'><mo>&prec;</mo><mo>&ne;</mo></mfrac>	 # dummy
EOT

	def test_fetchsymbol
		r = fetch_symbol

		#latex.ltx
		assert_equal(:subsup, r["\\log"])
		assert_equal(:subsup, r["\\deg"])
		assert_equal(:underover, r["\\lim"])
		assert_equal(:underover, r["\\gcd"])
		assert_equal(nil, r["\\bigl"])
		assert_equal(:subsup, r["\\$"])
		assert_equal(:subsup, r["\\}"])
		assert_equal(:subsup, r["\\copyright"])
		assert_equal(:subsup, r["\\%"])

		#fontmath.ltx
		assert_equal(:subsup, r["\\alpha"])
		assert_equal(:subsup, r["\\Gamma"])
		assert_equal(:underover, r["\\coprod"])
		assert_equal(:subsup, r["\\triangleleft"])
		assert_equal(:subsup, r["\\propto"])
		assert_equal(:subsup, r["\\ldotp"])
		assert_equal(:subsup, r["\\hbar"])
		assert_equal(nil, r["\\overrightarrow"])
		assert_equal(nil, r["\\n@space"])
		assert_equal(nil, r["\\rightarrowfill"])
		assert_equal(:subsup, r["\\lnot"])
		assert_equal(:subsup, r["\\|"])
		assert_equal(:subsup, r["\\lmoustache"])
		assert_equal(:subsup, r["\\arrowvert"])
		assert_equal(:subsup, r["\\uparrow"])
		assert_equal(:subsup, r["\\longleftarrow"])

		#amssymb.sty
		assert_equal(:subsup, r["\\boxdot"])
		assert_equal(:subsup, r["\\Doteq"])
		assert_equal(:subsup, r["\\Diamond"])

		#amsfonts.sty
		assert_equal(:subsup, r["\\ulcorner"])
		assert_equal(:subsup, r["\\urcorner"])
		assert_equal(:subsup, r["\\rightleftharpoons"])
		assert_equal(:subsup, r["\\leadsto"])
		assert_equal(nil, r["\\dabar@"])

		#amsmath.str
		assert_equal(:subsup, r["\\ldots"])
	end

	def test_parse_list
		h = parse_list(LIST)[1]
		assert_equal([:s, :o, ""], h["\\{"])
		assert_equal([:s, :o, :amp], h["\\&"])
		assert_equal([:s, :I], h["\\varepsilon"])
		assert_equal([:s, :i], h["\\Gamma"])
		assert_equal(nil, h["\\ensuremath"])
		assert_equal([:s, :i, ""], h["\\log"])
		assert_equal([:u, :i, ""], h["\\lim"])
		assert_equal([:s], h["\\dagger"])
		assert_equal([:s, :o, 0x25dc], h["\\braceld"])
		assert_equal([:s, :o, "-"], h["\\relbar"])
		assert_equal([:s, :o, "<mfrac mathsize='1%' linethickness='0'><mo>&prec;</mo><mo>&ne;</mo></mfrac>"], h["\\precneqq"])
	end

	def test_to_mathml
		def tm(com, h)
			to_mathml(com, h[com])
		end

		h = parse_list(LIST)[1]
		assert_equal("<mo>{</mo>", tm("\\{", h))
		assert_equal("<mo>&amp;</mo>", tm("\\&", h))
		assert_equal("<mi>&varepsilon;</mi>", tm("\\varepsilon", h))
		assert_equal("<mi mathvariant='normal'>&Gamma;</mi>", tm("\\Gamma", h))
		assert_equal("", tm("\\ensuremat", h))
		assert_equal("<mi>log</mi>", tm("\\log", h))
		assert_equal("<mo>&dagger;</mo>", tm("\\dagger", h))
		assert_equal("<mo>&#x25dc;</mo>", tm("\\braceld", h))
	end

	def test_gen_rb
		e = <<'EOT'
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
		assert_equal(e, gen_rb(LIST))
	end

	def test_mathml_rb_symbol_command
		a, h = parse_list(IO.read("symbols/list.txt"))
		a.each do |com|
			latex = "#{com}_a^b"
			m = to_mathml(com, h[com])
			unless h[com]
				case com
				when "\\,"
					e = "<msubsup><mspace width='0.167em' /><mi>a</mi><mi>b</mi></msubsup>"
				else
					e = "<msubsup><none /><mi>a</mi><mi>b</mi></msubsup>"
				end
			else
				if h[com][0] && h[com][0]==:u
					e = "<munderover>#{m}<mi>a</mi><mi>b</mi></munderover>"
				elsif h[com][0] && h[com][0]==:s
					e = "<msubsup>#{m}<mi>a</mi><mi>b</mi></msubsup>"
				else
					raise "#{com}"
				end
			end
			begin
				assert_nothing_raised{smml(latex, true)}
				assert_equal(e, smml(latex, true))
			rescue
				puts latex
				raise
			end
		end
	end

	def test_delims
		d = []
		fetch_symbol(d)

		MathML::LaTeX::BuiltinCommands::Delimiters.each do |i|
			assert(d.include?("\\#{i}"), "Add '#{i}'")
		end
		d.each do |i|
			assert(MathML::LaTeX::BuiltinCommands::Delimiters.include?(i[/^\\(.*)$/, 1]), "Missing '#{i}'")
		end
	end

	def test_missing
		p = load_preput_list(IO.read("symbols/list.txt"))
		h = fetch_symbol
		p.each_key do |k|
			test = h.include?(k) ? "" : k
			assert_equal("", test)
		end
	end
end
