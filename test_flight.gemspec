require_relative "lib/test_flight/version"

Gem::Specification.new do |spec|
  spec.name        = "test_flight"
  spec.version     = TestFlight::VERSION
  spec.authors     = ["Jay Bhoyar"]
  spec.email       = ["jaybhoyar1997@gmail.com"]
  spec.homepage    = "https://github.com/jaybhoyar/test_flight"
  spec.summary     = "TEST Flight GEM"
  spec.description = "TEST Flight GEM"
  spec.license     = "MIT"
  
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/jaybhoyar/test_flight"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.1.4", ">= 6.1.4.6"
  spec.add_dependency "faraday", "~> 1.9.3"
  spec.add_dependency "faraday_middleware", "~> 1.2"
  spec.add_dependency "railties", ">= 4.1.0"
end
