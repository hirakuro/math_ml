#!/usr/bin/ruby

$:.unshift("../")
require "cgi"
require "math_ml"

include MathML::LaTeX

BEC = /\\.|[^\\\n]/ # Back slash Escaped Character
TEXMF_DIR = "/usr/share/texmf-tetex"

def brace_nest(s)
	nest=0
	s.gsub(/(\{|\})/) do
		case $1
		when "{"
			nest+=1
			"{#{nest}."
		when "}"
			nest-=1
			"}#{nest+1}."
		end
	end
end

def load_style(name)
	r = IO.read("#{TEXMF_DIR}/tex/latex/#{name}").gsub(/^\%.*\n/, "").gsub(/^(#{BEC}*?)\%.*$/){$1}
end

def parse_DeclareMath(f, delims, robust_as_math = false)
	r = Hash.new

	f=f.gsub(/[a-zA-Z]\\Declare/, "")
	f.scan(/\\DeclareMathSymbol|\\DeclareRobustCommand/) do
		remain = Scanner.new($')
		com = remain.scan_block ? remain[1] : remain.scan_command
		next unless com=~/\A\\/ 
		remain.scan_option
		body = remain.scan_block ? remain[1] : remain.scan_any
		case body
		when /nomath/, /not@math/
			next
		when /\\mathord/, /\\mathalpha/, /\\mathbin/, /\\mathrel/, /\\mathpunct/
			r[com] = :subsup
		when /\\mathop/
			r[com] = :underover
		else
			r[com] = robust_as_math ? :subsup : body
		end
	end

	f.scan(/\\DeclareMathDelimiter\{(\\.+?)\}\s*\{(\\.+?)\}/m) do |m|
		case m[1]
		when "\\mathopen", "\\mathclose", "\\mathord", "\\mathrel"
			r[m[0]] = :subsup
		else
			raise "#{m[0]} : #{m[1]}"
		end
		delims << m[0]
	end

	f.scan(/\\let(\\.+?)=?(\\.*)/) do |m|
		r[m[0]] = m[1] unless r.include?(m[0]) # excepting "\let\com\undefined" or like it.
	end

	r
end

def trace_list(com, h, d)
	s = h[com]
	mmode = (s=~/\\ifmmode/ || s=~/mathinner/)
	if s.is_a?(String)
		sc = Scanner.new(s.dup.gsub(/[{}]/, ""))
		until sc.eos?
			b = sc.scan_any
			s.slice!(0, b.size)
			next unless h.include?(b)
			trace_list(b, h, d)
			h[com] = h[b] if h[com].is_a?(String)
			unless d.include?(com)
				d << com if d.include?(b)
			end
		end
	end
	if h[com].is_a?(String)
		if mmode
			h[com] = :subsup
		else
			h.delete(com)
		end
	end
end

def fetch_symbol(delims=[])
	r = {}

	f = load_style("base/latex.ltx")
	r.merge!(parse_DeclareMath(f, delims))
	f.scan(/^\\def(\\[a-zA-Z]+?)\{\\mathop(\W.*)$/) do |s|
		if s[1]=~/\\nolimits/
			r[s[0]] = :subsup
		else
			r[s[0]] = :underover
		end
	end
	f.scan(/\\chardef(\\.)=\`\1/) do |m|
		r[m[0]] = :subsup
	end

	f = load_style("base/latexsym.sty")
	r.merge!(parse_DeclareMath(f, delims))

	f = load_style("base/fontmath.ltx")
	r.merge!(parse_DeclareMath(f, delims, true))
	brace_nest(f).scan(/\\def(\\.+?)\{1\.(.*?)\}1\./m) do |m|
		if m[0]=~/@|#/
		elsif m[1]=~/\A\$/
		else
			r[m[0]] = :subsup
		end
	end
	f.scan(/\\def(\\[^\{]+?)(\\.+)/) do |m|
		raise StandardError.new("Uncaught commands")
	end

	f = load_style("amsfonts/amssymb.sty")
	r.merge!(parse_DeclareMath(f, delims))

	f = load_style("amsfonts/amsfonts.sty")
	r.merge!(parse_DeclareMath(f, delims))

	r.each_key do |k|
		r.delete(k) if k=~/@/
	end

	r.each_key do |k|
		trace_list(k, r, delims) if r[k].is_a?(String)
	end
	r
end

def sort_symbol_list_in(file, h)
	r = Array.new
	f = load_style(file)
	f.scan(/\\[a-zA-Z@\#]+|\\./) do |m|
		if h[m]
			r << m
			h.delete(m)
		end
	end
	r
end

def sorted_symbol_list(h)
	h = h.dup
	r = Array.new
	r.concat(sort_symbol_list_in("base/latex.ltx", h))
	r.concat(sort_symbol_list_in("base/fontmath.ltx", h))
	r.concat(sort_symbol_list_in("amsfonts/amssymb.sty", h))
	r.concat(sort_symbol_list_in("amsfonts/amsfonts.sty", h))
	r
end

def load_preput_list(list)
	r = {}
	list.each do |l|
		next if l=~/\A\s*\#/
		com, type, str = l.chomp.split(nil, 3)
		r[com] = [type.to_sym, str]
	end
	r
end

def output_list(h, preput=nil)
	p = preput ? load_preput_list(preput) : {}
	sorted_symbol_list(h).each do |k|
		data = p.include?(k) ? p[k][1] : ""
#		puts "#{k} #{h[k]} #{data}"
	end

	$stderr.puts "### Update"
	sorted_symbol_list(h).each do |k|
		$stderr.puts k unless p.include?(k)
	end

	$stderr.puts "### Conflict"
	sorted_symbol_list(h).each do |k|
		next unless p.include?(k)
		$stderr.puts k unless p[k][0]==h[k]
	end

	$stderr.puts "### Missing"
	p.each_key do |k|
		$stderr.puts k unless h.include?(k)
	end
end

def output_latex(h)
	puts <<'EOT'
\documentclass{article}
\usepackage{amssymb}
\newcommand{\bslash}{\texttt{\symbol{92}}}
\setlength{\oddsidemargin}{-1cm}
\setlength{\evensidemargin}{-1cm}
\begin{document}
EOT
	col = 4
	row=18
	l = sorted_symbol_list(h)
	(0 ... l.size).step(col*row) do |t|
		puts '\begin{tabular}{|'+"c|"*col+'}\hline'
		(0 ... col*row).step(col) do |r|
			next unless l[t+r]
			(0 ... col).each do |c|
				i = t+r+c
				com = l[i].to_s.gsub(/\\/, "\\bslash ").gsub(/([\$\{\}\#\%\&_])/){"\\#$1"}.
					gsub(/\|/, "\\texttt|")
				tex = l[i].to_s.dup
				if l[i]
					case h[l[i]]
					when :subsup
						tex << "_{sub}^{sup}"
					when :underover
						tex << "_{under}^{over}"
					else
						raise StandardError
					end
				end
				tex = "$\\displaystyle#{tex}$"
				str = (l[i] ? <<EOT : "")
\\begin{tabular}{c}
#{t+r+c} #{com} \\\\
#{tex}
\\end{tabular}
EOT
				print str+(c==(col-1) ? " \\\\ \\hline\n" : " & ")
			end
		end
		puts "\\end{tabular}\n\n"
	end
	puts '\end{document}'
end

def parse_list(list)
	a = []
	h = {}
	list.each do |l|
		next if l =~ /^\s*\#/
			com, type, str = l.chomp.split(nil, 3)

		case type
		when "subsup"
			type = :s
		when "underover"
			type = :u
		else
			raise l
		end

		str.slice!(/\s*\#.*$/)
		el = nil
		cl = nil
		s = nil
		case str
		when /^([oinI])([\-\:=])(.*)$/
			el = $1
			cl = $2
			s = $3
		when "v"
		when ""
			cl = true
		else
			raise l
		end
		a << com
		case cl
		when "-"
			h[com] = [type, el.to_sym, s ? s : ""]
		when ":"
			h[com] = [type, el.to_sym, s.to_s.length>0 ? s.to_sym : nil]
		when "="
			s = "0"+s if s=~/^x/
			h[com] = [type, el.to_sym, s.to_i(0)]
		when true
			h[com] = [type, nil, nil]
		when nil
			h[com] = nil
		else
			raise l
		end
		h[com].pop while h[com] && h[com].last==nil
	end
	[a, h]
end

def to_mathml(com, data)
	com = com[/^\\(.*)$/, 1]
	unless data
		""
	else
		data[1] = :o unless data[1]
		p=""
		case data[1]
		when :i
			p = " mathvariant='normal'" unless data[2] && data[2].is_a?(String)
		when :I
			data[1] = :i
		end

		case data[2]
		when String
			if data[2].length>0
				s = data[2]
			else
				s = com
			end
		when Symbol
			s = "&#{data[2].to_s};"
		when Integer
			s = "&\#x#{data[2].to_s(16)};"
		when nil
			s = "&#{com};"
		else
			raise data[2]
		end

		e = "m#{data[1].to_s}"
		"<#{e}#{p}>#{s}</#{e}>"
	end
end

def output_xhtml(list)
	a, h = parse_list(list)
	puts <<EOT
<?xml version='1.0'?>
<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN' 'http://www.w3.org/Math/DTD/mathml2/xhtml-math11-f.dtd'>
<html xmlns='http://www.w3.org/1999/xhtml'>
<body>
<ul>
EOT
	a.each do |k|
		raise k unless h.include?(k)
		e = to_mathml(k, h[k])
		e = nil unless e.length>0
		mml = e ? "<math xmlns='http://www.w3.org/1998/Math/MathML' display='inline'>#{e}</math>" : ""
		puts "<li>#{CGI.escapeHTML(k)} : #{mml}</li>"
	end
	puts <<EOT
</ul></body></html>
EOT
end

def output_hiki(h)
	col = 5
	row=20
	l = sorted_symbol_list(h)
	(0 ... l.size).step(col*row) do |t|
		(0 ... col*row).step(col) do |r|
			next unless l[t+r]
			print "||"
			(0 ... col).each do |c|
				i = t+r+c
				com = l[i].to_s.gsub(/\\/){"\\\\"}.gsub(/\$/){%[\\$]}.gsub(/([\{\}])/){"\\\\#$1"}
				tex = l[i].to_s.dup
				if l[i]
					case h[l[i]]
					when :subsup
						tex << "_{sub}^{sup}"
					when :underover
						tex << "_{under}^{over}"
					else
						raise StandardError
					end
				end
				print " #{com} $$#{tex}$$ ||"
			end
			puts ""
		end
	end
end

def gen_rb(list)
	a, h = parse_list(list)
	r = "SymbolCommands={\n"
	a.each do |k|
		d = h[k]
		unless d
			v = "nil"
		else
			v = "[:#{d[0].to_s}"
			unless d[1]
				v << "]"
			else
				v << ",:#{d[1].to_s}"
				unless d[2]
					v << "]"
				else
					case d[2]
					when String
						v << %[,"#{d[2].gsub(/\\/){"\\\\"}}"]
					when Symbol
						v << ",:#{d[2].to_s}"
					when Fixnum
						v << ",0x#{d[2].to_s(16)}"
					else
						raise [k, d]
					end
					v << "]"
				end
			end
		end
		r << %["#{k[/^\\(.*)/, 1].gsub(/\\/){"\\\\"}}"=>#{v},\n]
	end
	r << "}\n"
end

def output_delims
	d = []
	fetch_symbol(d)
	puts "Delimiters=["
	d.each do |i|
		puts %["#{i.gsub(/\\/){""}}",]
	end
	puts "]"
end

def read_list
	IO.read($*[1] || "list.txt")
end
if (File.expand_path(__FILE__)==File.expand_path($0)) && $*[0]
	case $*[0]
	when "list"
		preput = $*[1] ? IO.read($*[1]) : nil
		output_list(fetch_symbol, preput)
	when "latex"
		output_latex(fetch_symbol)
	when "xhtml"
		output_xhtml(read_list)
	when "hiki"
		output_hiki(fetch_symbol)
	when "delims"
		output_delims
	when "rb"
		puts gen_rb(read_list)
	end
end
