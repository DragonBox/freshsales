lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'freshsales/version'

Gem::Specification.new do |spec|
  spec.name        = 'freshsales'
  spec.version     = Freshsales::VERSION
  spec.authors     = ["Jerome Lacoste"]
  spec.email       = 'jerome@wewanttoknow.com'

  spec.required_ruby_version = '>= 2.4.0'

  spec.summary     = "Freshsales"
  spec.description = 'A wrapper for Freshsales API'

  spec.homepage    = 'https://github.com/DragonBox/freshsales'
  spec.license     = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  # using same minimal dependencies as gibbon, for the sake of compatibility
  spec.add_dependency 'faraday', '>= 0.16.0'
  spec.add_dependency 'multi_json', '>= 1.11.0'

  # Development only
  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "colored", '>= 1.2', '< 2.0.0'
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "github_changelog_generator"
  spec.add_development_dependency "highline", "~> 1.7.10"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.1.0"
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.2.3'
  spec.add_development_dependency 'rubocop', '~> 0.52.1'
  spec.add_development_dependency "webmock", "~> 3.3.0"
end
