# encoding: utf-8

Gem::Specification.new do |s|
  s.name        = "config-hash"
  s.version     = "0.7.0"
  s.author      = "Steve Shreeve"
  s.email       = "steve.shreeve@gmail.com"
  s.summary     = "A safe, homoiconic, Ruby hash supporting dot notation"
  s.description = "This gem makes it easy to work with configuration data."
  s.homepage    = "https://github.com/shreeve/config-hash"
  s.license     = "MIT"
  s.files       = `git ls-files`.split("\n") - %w[.gitignore]
end
