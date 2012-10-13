Gem::Specification.new do |s|
  s.name         = "redhead"
  s.version      = "0.0.6"
  s.authors      = ["Adam Prescott"]
  s.email        = ["adam@aprescott.com"]
  s.homepage     = "https://github.com/aprescott/redhead"
  s.summary      = "String header metadata."
  s.description  = "String header metadata."
  s.files        = Dir["{lib/**/*,test/**/*}"] + %w[redhead.gemspec .gemtest LICENSE Gemfile rakefile README.md]
  s.require_path = "lib"
  s.test_files   = Dir["test/*"]
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
end
