lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'super_callbacks/version'

Gem::Specification.new do |spec|
  spec.name          = 'super_callbacks'
  spec.version       = SuperCallbacks::VERSION
  spec.authors       = ['Jules Roman B. Polidario']
  spec.email         = ['jules@topfloor.ie']

  spec.summary       = 'Allows `before` and `after` callbacks to any Class. Supports dirty checking of instance variables changes, class and instance level callbacks, conditional callbacks, and inherited callbacks.'
  spec.description   = 'Allows `before` and `after` callbacks to any Class. Supports dirty checking of instance variables changes, class and instance level callbacks, conditional callbacks, and inherited callbacks. Focuses on performance and flexibility as intended primarily for game development, and event-driven apps.'
  spec.homepage      = 'https://github.com/jrpolidario/super_callbacks'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'byebug', '~> 9.0'
end
