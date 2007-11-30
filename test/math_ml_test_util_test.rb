# Test for test_util
#
# Copyright (C) 2006, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.

require "test/unit"
require "test/math_ml_test_util"
require "math_ml"

class TC_Util4TC_MathML < Test::Unit::TestCase
	include Util4TC_MathML

	def test_strip
		assert_equal("><", strip(">\n \t<"))
		assert_equal("<mn>1</mn>", smml("1"))
	end

	def test_strip_mathml
		src = "<math test='dummy'> <a> b </a> <c> d </c></math>"
		assert_equal("<a>b</a><c>d</c>", strip_mathml(src))
	end
end
