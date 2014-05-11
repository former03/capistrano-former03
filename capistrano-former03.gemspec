# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/former03/version'

Gem::Specification.new do |spec|
  spec.name          = "capistrano-former03"
  spec.version       = Capistrano::Former03::VERSION
  spec.authors       = ["Christian Simon"]
  spec.email         = ["simon@swine.de"]
  spec.summary       = %q{Capistrano with extensions for FORMER 03}
  spec.description   = %q{Capistrano with extensions for FORMER 03}
  spec.homepage      = "https://github.com/former03/capistrano-former03"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "capistrano", "= 3.2.1"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "capistrano-spec"
  spec.add_development_dependency "rspec", ">= 2.5.0"
end
