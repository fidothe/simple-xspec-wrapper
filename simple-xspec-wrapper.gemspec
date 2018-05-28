
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "xspec/version"

Gem::Specification.new do |spec|
  spec.name          = "simple-xspec-wrapper"
  spec.version       = XSpec::VERSION
  spec.authors       = ["Matt Patterson"]
  spec.email         = ["matt@reprocessed.org"]

  spec.summary       = %q{A simple wrapper to run a suite of XSpec tests independently}
  spec.homepage      = "https://github.com/fidothe/simple-xspec-wrapper"
  spec.license       = "MIT"

  spec.platform      = 'java'
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|\.ruby-version)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "saxon-xslt", "~> 0.8"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
