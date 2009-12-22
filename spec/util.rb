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

module MathML
	module Spec
		module Util
			def raise_parse_error(message, done, rest)
				simple_matcher("parse_error") do |given|
					given.should raise_error(MathML::LaTeX::ParseError){ |e|
						e.message.should == message
						e.done.should == done
						e.rest.should == rest
					}
				end
			end

			def new_parser
				MathML::LaTeX::Parser.new
			end

			def strip_math_ml(math_ml)
				math_ml.gsub(/>\s*/, ">").gsub(/\s*</, "<")[/\A<math [^>]*>(.*)<\/math>\Z/m, 1]
			end

			def smml(src, display_style=false, parser=nil)
				parser ||= new_parser
				strip_math_ml(parser.parse(src, display_style).to_s)
			end
		end
	end
end
