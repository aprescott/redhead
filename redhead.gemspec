Gem::Specification.new do |s|
  s.name         = "redhead"
  s.version      = "0.0.1"
  s.authors      = ["Adam Prescott"]
  s.email        = ["adam@aprescott.com"]
  s.homepage     = "https://github.com/aprescott/redhead"
  s.summary      = "String header metadata."
  s.description  = "String header metadata."
  s.files        = Dir["{lib/**/*,test/**/*}"] + %w[LICENSE Gemfile rakefile README.md]
  s.require_path = "lib"
  s.test_files   = Dir["test/*"]
  s.has_rdoc     = false
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
end
