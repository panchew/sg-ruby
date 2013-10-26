# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'survey_gizmo/version'

Gem::Specification.new do |spec|
  spec.name          = "sg-ruby"
  spec.version       = SurveyGizmo::VERSION
  spec.authors       = ["Francisco Guzmán"]
  spec.email         = ["jf.guzman76@gmail.com"]
  spec.description   = %q{A Ruby interface for the SurveyGizmo REST API}
  spec.summary       = %q{This gem uses OAuth for authentication and Typhoeus for http requests}
  spec.homepage      = "https://github.com/panchew/sg-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "typhoeus"
  spec.add_development_dependency "oauth"

end
