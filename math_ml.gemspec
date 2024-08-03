# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'math_ml'
  s.version = '1.0.0'
  s.summary = 'MathML Library'
  s.author = 'KURODA Hiraku'
  s.email = 'hirakuro@gmail.com'
  s.homepage = 'https://github.com/hirakuro/math_ml'
  s.license = 'GPL-2.0-only'
  s.metadata['rubygems_mfa_required'] = 'true'

  s.required_ruby_version = '>= 3.2.0'

  s.add_dependency 'eim_xml', '~> 1.0.0'

  s.files = Dir['LICENSE', 'lib/**/*']
end
