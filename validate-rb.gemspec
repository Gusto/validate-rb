# frozen_string_literal: true

require_relative 'lib/validate/version'

Gem::Specification.new do |spec|
  spec.name          = 'validate-rb'
  spec.version       = Validate::VERSION
  spec.authors       = ['Bulat Shakirzyanov']
  spec.email         = ['bulat.shakirzyanov@gusto.com']

  spec.summary       = 'Yummy constraint validations for Ruby'
  spec.description   = 'Simple, powerful, and constraint-based validation'
  spec.homepage      = 'https://github.com/Gusto/validate-rb'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata    = {
    'homepage_uri' => 'https://github.com/Gusto/validate-rb',
    'changelog_uri' => 'https://github.com/Gusto/validate-rb/releases',
    'source_code_uri' => 'https://github.com/Gusto/validate-rb',
    'bug_tracker_uri' => 'https://github.com/Gusto/validate-rb/issues',
  }

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'aruba'
  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'cucumber', '~> 4.0'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'sorbet'
  spec.add_development_dependency 'yard'
end
