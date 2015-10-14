# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "packer/version"

Gem::Specification.new do |spec|
  spec.name          = "p4r"
  spec.version       = Packer::VERSION
  spec.authors       = ["Yamashita Yuu"]
  spec.email         = ["peek824545201@gmail.com"]
  spec.summary       = %q{Yet another command-line tool to build machine image on cloud platforms}
  spec.description   = %q{Yet another command-line tool to build machine image on cloud platforms}
  spec.homepage      = "https://github.com/yyuu/p4r"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3.0"

  spec.add_dependency "multi_json", "~> 1.11.2"
  spec.add_dependency "oj", "~> 2.12.14"
  spec.add_dependency "parallel", "~> 1.6.1"
end
