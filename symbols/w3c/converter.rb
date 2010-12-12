#!/usr/bin/ruby
require "rubygems"

HERE = File.dirname(__FILE__)
$:.unshift("#{HERE}/../../lib", "#{HERE}/../../external/lib")

require "math_ml"
require "math_ml/latex/builtin/symbol/entity_reference"
require "open-uri"
require "fileutils"
require "nokogiri"

module MathML
	module LaTeX
		module BuiltinCommands
		end
	end
end

class CharacterCommandGenerator
	class Downloader
		URIS = ["http://www.w3.org/TR/MathML2/byalpha.html"]

		def get(uri)
			open(uri){|f| f.read}
		end

		def start
			Dir.mkdir("#{HERE}/html") unless File.exist?("#{HERE}/html")
			URIS.each do |uri|
				filename = "#{HERE}/html/#{uri[/\/([^\/]*)\z/, 1]}"
				unless File.exist?(filename)
					open(filename, "w"){|f| f.print(get(uri))}
				end
			end

			self
		end
	end
	Downloader.new.start

	class Converter
		FILE_NAMES = Dir.glob("#{HERE}/html/*.html")
		attr_reader :utf8, :ncr

		def parser(filename)
			hash = {}
			Nokogiri.HTML(IO.read(filename)).search("pre")[0].text.each_line do |line|
				next if line=~/\A\s*\z/
				a = line.split(/\s*,\s*/)
				name = a.shift
				string = a.shift.scan(/[0-9A-Fa-f]+/).map{|i| i.to_i(16)}.pack("U*")
				if hash.key?(name)
					raise "OOPS: #{hash[name]} : #{string}" if hash.key?(name) && hash[name]!=string
				end
				hash[name] = string
			end

			hash.keys.each do |k|
				@utf8[k] = hash[k]
				@ncr[k] = hash[k].unpack("U*").map{|i| "&#x#{i.to_s(16)};"}.join
			end
		end

		def start
			@utf8 = {}
			@ncr = {}
			FILE_NAMES.each do |filename|
				parser(filename)
			end

			self
		end
	end

	class Generator
		KEYS = []
		IO.read("#{HERE}/../../lib/math_ml/latex/builtin/symbol/entity_reference/map.rb").scan(/^\"([^\"]+)\"=>/){|m| KEYS << m[0]}

		attr_reader :converter

		def start
			@converter = Converter.new
			converter.start
			open("#{HERE}/table.rb", "w") do |f|
				f.puts "### keys ###", "["
				converter.utf8.keys.sort.each do |k|
					f.puts ":#{k},"
				end
				f.puts "]\n\n", "### utf8 ###", "{"
				converter.utf8.keys.sort.each do |k|
					f.puts ":#{k} => \"#{converter.utf8[k].gsub(/\\/, "\\\\\\\\").gsub(/\"/, "\\\\\"")}\","
				end
				f.puts "}\n\n", "### character reference ###", "{"
				converter.ncr.keys.sort.each do |k|
					f.puts ":#{k} => \"#{converter.ncr[k]}\","
				end
				f.puts "}"
			end

			open("#{HERE}/sample.xhtml", "w") do |f|
				converter.utf8.keys.sort.each do |k|
					f.puts "&#{k};"
				end
			end
		end

		new.start
	end
end
