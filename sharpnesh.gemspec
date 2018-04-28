
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sharpnesh/version'

Gem::Specification.new do |spec|
  spec.name          = 'sharpnesh'
  spec.version       = Sharpnesh::VERSION
  spec.authors       = ['autopp']
  spec.email         = ['autopp.inc@gmail.com']

  spec.summary       = 'Keep sharpness of your shell script'
  spec.description   = 'Automatic Bash code checker'
  spec.homepage      = 'https://github.com/autopp/sharpnesh'
  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'rubocop', '~> 0.55.0'
end
