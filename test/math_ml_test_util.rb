# Utility for tests
#
# Copyright (C) 2006, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.

class Symbol
	def <=>(s)
		self.to_s<=>s.to_s
	end
end
class Hash
	def each
		keys.sort.each do |k|
			yield(k, self[k])
		end
	end
end

module Util4TC_MathML
	def setup
		@p = MathML::LaTeX::Parser.new unless @p
		super
	end

	def strip(str)
		str.gsub(/>\s*/, ">").gsub(/\s*</, "<")
	end

	def strip_mathml(mathml)
		strip(mathml)[/\A<math [^>]*>(.*)<\/math>\Z/m, 1]
	end

	def smml(str, display_style=false, p=nil)
		p = @p unless p
		mml = p.parse(str, display_style).to_s
		strip_mathml(mml)
	end

	def parse_error(e)
		[e.message, e.done, e.rest].flatten
	end

	def assert_parse_error(message=nil, done=nil, rest=nil, write=false)
		e = assert_raises(MathML::LaTeX::ParseError){yield}
		puts e.inspect if write
		assert_equal([message, done, rest], parse_error(e))
	end
end
