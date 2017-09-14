require_relative 'lib/property-list/version'

Gem::Specification.new do |spec|
  spec.name          = "property-list"
  spec.version       = PropertyList::VERSION
  spec.authors       = ["Luikore"]
  spec.email         = 'no@email'

  spec.summary       = "Property list (plist) library with all formats support"
  spec.description   = "Fully featured property_plist library.
Can load and dump XML/ASCII/Binary/SMIME propertyplist and offer fine-grained formatting options.
Cross platform, clean code, performance tuned, no dependency."
  spec.homepage      = "https://github.com/luikore/property-list"
  spec.license       = "BSD-3-Clause"

  spec.files = `git ls-files -z`.split("\x0").grep_v %r{^(test|spec|features)/}
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "test-unit", "~> 1.2"
  spec.add_development_dependency "pry", "~> 0.10"
  spec.add_development_dependency "simplecov", "~> 0.14"
end
