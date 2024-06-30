require "spec_util"
require "math_ml"

describe MathML::LaTeX::Macro do
	include MathML::Spec::Util

	before(:all) do
		@src = <<'EOT'
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
EOT
	end

	before do
		@m = MathML::LaTeX::Macro.new
		@m.parse(@src)
	end

	it "#parse" do
		@m = MathML::LaTeX::Macro.new
		expect{@m.parse(@src)}.not_to raise_error

		@m = MathML::LaTeX::Macro.new
		expect{@m.parse('\newcommand{notcommand}{}')}.to raise_parse_error("Need newcommand.", '\\newcommand{', "notcommand}{}")
		expect{@m.parse('\newcommand{\separated command}{}')}.to raise_parse_error("Syntax error.", '\newcommand{\separated', " command}{}")
		expect{@m.parse('\newcommand{\nobody}')}.to raise_parse_error("Need parameter.", '\newcommand{\nobody}', "")
		expect{@m.parse('\newcommand{\noparam}{#1}')}.to raise_parse_error("Parameter \# too large.", '\newcommand{\noparam}{#', "1}")
		expect{@m.parse('\newcommand{\overopt}[1]{#1#2}')}.to raise_parse_error("Parameter \# too large.", '\newcommand{\overopt}[1]{#1#', "2}")
		expect{@m.parse('\newcommand{\strangeopt}[-1]')}.to raise_parse_error("Need positive number.", '\newcommand{\strangeopt}[', "-1]")
		expect{@m.parse('\newcommand{\strangeopt}[a]')}.to raise_parse_error("Need positive number.", '\newcommand{\strangeopt}[', "a]")

		expect{@m.parse('\newenvironment{\command}{}{}')}.to raise_parse_error("Syntax error.", '\newenvironment{', '\command}{}{}')
		expect{@m.parse('\newenvironment{nobegin}')}.to raise_parse_error("Need begin block.", '\newenvironment{nobegin}', "")
		expect{@m.parse('\newenvironment{noend}{}')}.to raise_parse_error("Need end block.", '\newenvironment{noend}{}', "")
		expect{@m.parse('\newenvironment{noparam}{#1}{}')}.to raise_parse_error("Parameter \# too large.", '\newenvironment{noparam}{#', "1}{}")
		expect{@m.parse('\newenvironment{overparam}[1]{#1#2}{}')}.to raise_parse_error("Parameter \# too large.", '\newenvironment{overparam}[1]{#1#', "2}{}")
		expect{@m.parse('\newenvironment{strangeparam}[-1]{}{}')}.to raise_parse_error("Need positive number.", '\newenvironment{strangeparam}[', "-1]{}{}")
		expect{@m.parse('\newenvironment{strangeparam}[a]{}{}')}.to raise_parse_error("Need positive number.", '\newenvironment{strangeparam}[', "a]{}{}")

		expect{@m.parse('\newcommand{\valid}{OK} \invalid{\test}{NG}')}.to raise_parse_error("Syntax error.", '\newcommand{\valid}{OK} ', '\invalid{\test}{NG}')
		expect{@m.parse('\newcommand{\valid}{OK} invalid{\test}{NG}')}.to raise_parse_error("Syntax error.", '\newcommand{\valid}{OK} ', 'invalid{\test}{NG}')

		expect{@m.parse('\newcommand{\newcom}[test')}.to raise_parse_error("Option not closed.", '\newcommand{\newcom}', '[test')
		expect{@m.parse('\newcommand{\newcom}[1][test')}.to raise_parse_error("Option not closed.", '\newcommand{\newcom}[1]', '[test')
		expect{@m.parse('\newcommand{\newcom}[1][]{#1#2}')}.to raise_parse_error("Parameter \# too large.", '\newcommand{\newcom}[1][]{#1#', '2}')
		expect{@m.parse('\newenvironment{newenv}[1][test')}.to raise_parse_error("Option not closed.", '\newenvironment{newenv}[1]', '[test')
		expect{@m.parse('\newenvironment{newenv}[1][test')}.to raise_parse_error("Option not closed.", '\newenvironment{newenv}[1]', '[test')

		expect{@m.parse('\newcommand{\newcom')}.to raise_parse_error("Block not closed.", '\newcommand', '{\newcom')
		expect{@m.parse('\newcommand{\newcom}{test1{test2}{test3')}.to raise_parse_error("Block not closed.", '\newcommand{\newcom}', '{test1{test2}{test3')

		expect{@m.parse('\newenvironment{newenv}[1][]{#1 #2}')}.to raise_parse_error("Parameter \# too large.", '\newenvironment{newenv}[1][]{#1 #', '2}')
	end

	it "#commands" do
		expect(@m.commands("newcom").num).to eq(0)
		expect(@m.commands("paramcom").num).to eq(2)
		expect(@m.commands("no")).to eq(nil)
	end

	it "#expand_command" do
		expect(@m.expand_command("not coommand", [])).to eq(nil)

		expect(@m.expand_command("newcom", [])).to eq("test")
		expect(@m.expand_command("newcom", ["dummy_param"])).to eq("test")
		expect(@m.expand_command("paramcom", ["1", "2"])).to eq("param2 2, param1 1.")
		expect(@m.expand_command("paramcom", ["12", "34"])).to eq("param2 34, param1 12.")
		expect{@m.expand_command("paramcom", ["12"])}.to raise_parse_error("Need more parameter.", "", "")
		expect{@m.expand_command("paramcom", [])}.to raise_parse_error("Need more parameter.", "", "")
	end

	it "#environments" do
		expect(@m.environments("newenv").num).to eq(0)
		expect(@m.environments("paramenv").num).to eq(2)
		expect(@m.environments("not_env")).to eq(nil)
		expect(@m.environments("separated environment").num).to eq(0)
	end

	it "#expand_environment" do
		expect(@m.expand_environment('notregistered', "dummy", [])).to eq(nil)
		expect(@m.expand_environment("newenv", "body", [])).to eq(' begin_newenv body end_newenv ')
		expect(@m.expand_environment("paramenv", "body", ["1", "2"])).to eq(' begin 1:1, 2:2 body end 2:2 1:1 ')
		expect(@m.expand_environment("paramenv", "body", ["12", "34"])).to eq(' begin 1:12, 2:34 body end 2:34 1:12 ')
		expect{@m.expand_environment("paramenv", "body", ["1"])}.to raise_parse_error("Need more parameter.", "", "")
		expect{@m.expand_environment("paramenv", "body", [])}.to raise_parse_error("Need more parameter.", "", "")
		expect(@m.expand_environment("nothing", "body", [])).to eq('  body  ')
		expect(@m.expand_environment("separated environment", "body", [])).to eq(' sep body env ')
		expect(@m.expand_environment("E", "body", [])).to eq(' N body V ')
	end

	it "#expand_with_options" do
		src = <<'EOT'
\newcommand{\opt}[1][x]{#1}
\newcommand{\optparam}[2][]{#1#2}
\newenvironment{newenv}[1][x]{s:#1}{e:#1}
\newenvironment{optenv}[2][]{s:#1}{e:#2}
EOT

		m = MathML::LaTeX::Macro.new
		m.parse(src)

		expect(m.expand_command("opt", [])).to eq('x')
		expect(m.expand_command("opt", [], "1")).to eq('1')

		expect(m.expand_command("optparam", ["1"])).to eq('1')
		expect(m.expand_command("optparam", ["1"], "2")).to eq('21')

		expect(m.expand_environment("newenv", "test", [])).to eq(" s:x test e:x ")
		expect(m.expand_environment("newenv", "test", [], "1")).to eq(" s:1 test e:1 ")

		expect(m.expand_environment("optenv", "test", ["1"])).to eq(" s: test e:1 ")
		expect(m.expand_environment("optenv", "test", ["1"], "2")).to eq(" s:2 test e:1 ")
	end
end
