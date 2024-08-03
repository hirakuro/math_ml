# MathML Library
#
# Copyright (C) 2005, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.

require 'strscan'
module MathML
  require 'eim_xml'

  class XMLElement < EimXML::Element
    def pop
      @contents.pop
    end
  end

  def self.pcstring(s, encoded = false)
    s.is_a?(EimXML::PCString) ? s : EimXML::PCString.new(s, encoded)
  end

  class Error < StandardError; end
end

require 'math_ml/element'
require 'math_ml/symbol/entity_reference'
require 'math_ml/latex'
