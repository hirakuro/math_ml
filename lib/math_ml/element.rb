module MathML
	class Element < XMLElement
		attr_reader :display_style

		def as_display_style
			@display_style = true
			self
		end
	end

	module Variant
		NORMAL = "normal"
		BOLD = "bold"
		BOLD_ITALIC = "bold-italic"
		def variant=(v)
			self["mathvariant"] = v
		end
	end

	module Align
		CENTER = "center"
		LEFT = "left"
		RIGHT = "right"
	end

	module Line
		SOLID = "solid"
		NONE = "none"
	end

	class Math < XMLElement
		def initialize(display_style)
			super("math", "xmlns"=>"http://www.w3.org/1998/Math/MathML")
			self[:display] = display_style ? "block" : "inline"
		end
	end

	class Row < Element
		def initialize
			super("mrow")
		end
	end

	class None < Element
		def initialize
			super("none")
		end
	end

	class Space < Element
		def initialize(width)
			super("mspace", "width"=>width)
		end
	end

	class Fenced < Element
		attr_reader :open, :close

		def initialize
			super("mfenced")
		end

		def open=(o)
			o = "" if o.to_s=="." || !o
			o = "{" if o.to_s=="\\{"
			self[:open] = MathML.pcstring(o, true)
		end

		def close=(c)
			c = "" if c.to_s=="." || !c
			c = "}" if c.to_s=="\\}"
			self[:close] = MathML.pcstring(c, true)
		end
	end

	class Frac < Element
		def initialize(numerator, denominator)
			super("mfrac")
			self << numerator
			self << denominator
		end
	end

	class SubSup < Element
		attr_reader :sub, :sup, :body

		def initialize(display_style, body)
			super("mrow")
			as_display_style if display_style
			@body = body

			update_name
		end

		def update_name
			if @sub || @sup
				name = "m"
				name << (@sub ? (@display_style ? "under" : "sub") : "")
				name << (@sup ? (@display_style ? "over" : "sup") : "")
			else
				name = "mrow"
			end
			self.name = name
		end
		protected :update_name

		def update_contents
			contents.clear
			contents << @body
			contents << @sub if @sub
			contents << @sup if @sup
		end
		protected :update_contents

		def sub=(sub)
			@sub = sub
			update_name
		end

		def sup=(sup)
			@sup = sup
			update_name
		end

		def write_to(out="")
			update_contents
			super
		end
	end

	class Over < Element
		def initialize(base, over)
			super("mover")
			self << base << over
		end
	end

	class Under < Element
		def initialize(base, under)
			super("munder")
			self << base << under
		end
	end

	class Number < Element
		def initialize
			super("mn")
		end
	end

	class Identifier < Element
		def initialize
			super("mi")
		end
	end

	class Operator < Element
		def initialize
			super("mo")
		end
	end

	class Text < Element
		def initialize
			super("mtext")
		end
	end

	class Sqrt < Element
		def initialize
			super("msqrt")
		end
	end

	class Root < Element
		def initialize(index, base)
			super("mroot")
			self << base
			self << index
		end
	end

	class Table < Element
		def initialize
			super("mtable")
		end

		def set_align_attribute(name, a, default)
			if a.is_a?(Array) && a.size>0
				value = ""
				a.each do |i|
					value << " "+i
				end
				if value =~ /^( #{default})*$/
					@attributes.delete(name)
				else
					@attributes[name] = value.strip
				end
			else
				@attributes.delete(name)
			end
		end

		def aligns=(a)
			set_align_attribute("columnalign", a, Align::CENTER)
		end

		def vlines=(a)
			set_align_attribute("columnlines", a, Line::NONE)
		end

		def hlines=(a)
			set_align_attribute("rowlines", a, Line::NONE)
		end
	end

	class Tr < Element
		def initialize
			super("mtr")
		end
	end

	class Td < Element
		def initialize
			super("mtd")
		end
	end
end
