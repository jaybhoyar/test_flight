# frozen_string_literal: true

require_relative "lib/test_flight/version"

Gem::Specification.new do |spec|
  spec.name = "test_flight"
  spec.version = TestFlight::VERSION
  spec.authors = ["Jay Bhoyar"]
  spec.email = ["jaybhoyar1997@gmail.com"]

  spec.summary = "TEST Flight GEM"
  spec.description = "TEST Flight GEM"
  spec.homepage = "https://github.com/jaybhoyar/test_flight"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/jaybhoyar/test_flight"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "faraday", "~> 1.9.3"
  spec.add_dependency "faraday_middleware", "~> 1.2"
  spec.add_dependency "railties", ">= 4.1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
